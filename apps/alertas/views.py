from rest_framework import generics, permissions
from .models import Alerta
from .serializers import AlertaSerializer
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from apps.notifications.fcm import enviar_para_todos


class IsAuthoridade(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'autoridade'


class AlertaListCreateView(generics.ListCreateAPIView):
    serializer_class = AlertaSerializer

    def get_queryset(self):
        # Autoridade vê todos os alertas (histórico); demais veem apenas os ativos
        if hasattr(self.request.user, 'role') and self.request.user.role == 'autoridade':
            return Alerta.objects.all().order_by('-created_at')
        return Alerta.objects.filter(vigente=True).order_by('-created_at')

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthoridade()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        alerta = serializer.save(autoridade=self.request.user)
        # Push para todos os usuários
        enviar_para_todos(
            titulo=f'⚠️ Alerta — {alerta.nivel_risco.upper()}',
            corpo=alerta.titulo,
            data={'alerta_id': str(alerta.id), 'type': 'alerta'},
        )
        # Broadcast WebSocket
        channel_layer = get_channel_layer()
        if channel_layer is not None:
            async_to_sync(channel_layer.group_send)(
                'all_users',
                {'type': 'novo_alerta', 'alerta': AlertaSerializer(alerta).data}
            )


class AlertaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Alerta.objects.all()
    serializer_class = AlertaSerializer
    permission_classes = [IsAuthoridade]
