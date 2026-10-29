from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import json

from .models import Ocorrencia
from .serializers import OcorrenciaSerializer, OcorrenciaUpdateSerializer, DuplicataCheckSerializer
from .services import calcular_score, detectar_duplicata
from apps.notifications.fcm import enviar_para_autoridades


class IsAuthoridade(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'autoridade'


class OcorrenciaListCreateView(generics.ListCreateAPIView):
    serializer_class = OcorrenciaSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['status', 'nivel_fogo']
    search_fields = ['descricao', 'endereco']
    ordering_fields = ['score_prioridade', 'created_at', 'nivel_fogo']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        # Autoridade vê todas; cidadão vê só as suas
        if user.role == 'autoridade':
            return Ocorrencia.objects.all()
        return Ocorrencia.objects.filter(usuario=user)

    def perform_create(self, serializer):
        user = self.request.user
        data = self.request.data

        # Score calculado no servidor
        score_data = calcular_score(
            nivel_fogo=data.get('nivel_fogo', 'baixo'),
            ha_fumaca=data.get('ha_fumaca', False),
            proximo_residencia=data.get('proximo_residencia', False),
            latitude=float(data.get('latitude', 0)),
            longitude=float(data.get('longitude', 0)),
        )

        ocorrencia = serializer.save(
            usuario=None if data.get('anonima') else user,
            score_prioridade=score_data['score'],
        )

        # Push para autoridades via FCM
        enviar_para_autoridades(
            titulo=f'🔥 Nova Denúncia — {ocorrencia.nivel_fogo}',
            corpo=ocorrencia.descricao[:100] or 'Nova ocorrência registrada',
            data={'ocorrencia_id': str(ocorrencia.id), 'type': 'new_report'},
        )

        # Broadcast WebSocket para autoridades conectadas (só se Channels estiver configurado)
        channel_layer = get_channel_layer()
        if channel_layer is not None:
            async_to_sync(channel_layer.group_send)(
                'authorities',
                {
                    'type': 'nova_ocorrencia',
                    'ocorrencia': OcorrenciaSerializer(ocorrencia).data,
                }
            )


class OcorrenciaDetailView(generics.RetrieveUpdateAPIView):
    queryset = Ocorrencia.objects.all()

    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH']:
            return [IsAuthoridade()]
        return [permissions.IsAuthenticated()]

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return OcorrenciaUpdateSerializer
        return OcorrenciaSerializer

    def perform_update(self, serializer):
        ocorrencia = serializer.save()
        # Notifica o cidadão que fez a denúncia via WebSocket (só se Channels estiver configurado)
        channel_layer = get_channel_layer()
        if ocorrencia.usuario and channel_layer is not None:
            async_to_sync(channel_layer.group_send)(
                f'user_{ocorrencia.usuario.id}',
                {
                    'type': 'ocorrencia_atualizada',
                    'ocorrencia': OcorrenciaSerializer(ocorrencia).data,
                }
            )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def score_view(request, pk):
    try:
        oc = Ocorrencia.objects.get(pk=pk)
    except Ocorrencia.DoesNotExist:
        return Response({'detail': 'Não encontrada'}, status=404)

    data = calcular_score(oc.nivel_fogo, oc.ha_fumaca, oc.proximo_residencia,
                          float(oc.latitude), float(oc.longitude))
    return Response({
        'score': data['score'],
        'nivel_calculado': data['nivel'],
        'recomendacao': data['recomendacao'],
    })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def duplicata_view(request):
    serializer = DuplicataCheckSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    result = detectar_duplicata(**serializer.validated_data)
    return Response(result)
