from urllib.parse import parse_qs
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken


@database_sync_to_async
def _get_user(token_str):
    from apps.accounts.models import Usuario
    try:
        token = AccessToken(token_str)
        return Usuario.objects.get(pk=token['user_id'])
    except Exception:
        return AnonymousUser()


class JwtAuthMiddleware:
    """Autentica conexões WebSocket via token JWT no query string."""

    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        qs = parse_qs(scope.get('query_string', b'').decode())
        token = qs.get('token', [None])[0]
        scope['user'] = await _get_user(token) if token else AnonymousUser()
        return await self.inner(scope, receive, send)
