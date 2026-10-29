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
    queryset = Alerta.objects.filter(vigente=True)
    serializer_class = AlertaSerializer

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
        async_to_sync(channel_layer.group_send)(
            'all_users',
            {'type': 'novo_alerta', 'alerta': AlertaSerializer(alerta).data}
        )


class AlertaDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Alerta.objects.all()
    serializer_class = AlertaSerializer
    permission_classes = [IsAuthoridade]
