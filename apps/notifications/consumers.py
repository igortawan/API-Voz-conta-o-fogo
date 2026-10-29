import json
from channels.generic.websocket import AsyncWebsocketConsumer


class ReportConsumer(AsyncWebsocketConsumer):
    """
    WebSocket que substitui os listeners do Firestore.

    Grupos:
      • 'authorities'       — autoridades recebem TODA nova ocorrência
      • 'user_{uuid}'       — cidadão recebe atualizações das suas próprias denúncias
      • 'all_users'         — alertas de risco climático para todos
    """

    async def connect(self):
        user = self.scope.get('user')
        if not user or not user.is_authenticated:
            await self.close()
            return

        self.user = user
        # Entra no grupo pessoal (recebe status das próprias denúncias)
        await self.channel_layer.group_add(f'user_{user.id}', self.channel_name)
        # Entra no grupo global de alertas
        await self.channel_layer.group_add('all_users', self.channel_name)
        # Autoridade entra no grupo de novas ocorrências
        if user.role == 'autoridade':
            await self.channel_layer.group_add('authorities', self.channel_name)

        await self.accept()

    async def disconnect(self, code):
        if hasattr(self, 'user'):
            await self.channel_layer.group_discard(f'user_{self.user.id}', self.channel_name)
            await self.channel_layer.group_discard('all_users', self.channel_name)
            if self.user.role == 'autoridade':
                await self.channel_layer.group_discard('authorities', self.channel_name)

    # ── Handlers de mensagens recebidas do Django ─────────────────────────────

    async def nova_ocorrencia(self, event):
        await self.send(text_data=json.dumps({
            'type': 'nova_ocorrencia',
            'ocorrencia': event['ocorrencia'],
        }))

    async def ocorrencia_atualizada(self, event):
        await self.send(text_data=json.dumps({
            'type': 'ocorrencia_atualizada',
            'ocorrencia': event['ocorrencia'],
        }))

    async def novo_alerta(self, event):
        await self.send(text_data=json.dumps({
            'type': 'novo_alerta',
            'alerta': event['alerta'],
        }))
