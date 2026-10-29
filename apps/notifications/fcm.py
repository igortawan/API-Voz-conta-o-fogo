from django.conf import settings


def _get_pusher():
    from pyfcm import FCMNotification
    key = settings.FCM_SERVER_KEY
    if not key:
        return None
    return FCMNotification(api_key=key)


def enviar_para_autoridades(titulo: str, corpo: str, data: dict = None):
    """Envia push para todos os dispositivos de autoridade cadastrados."""
    from apps.accounts.models import Usuario
    tokens = list(
        Usuario.objects.filter(role='autoridade', is_active=True)
        .exclude(fcm_token='')
        .values_list('fcm_token', flat=True)
    )
    if not tokens:
        return
    push = _get_pusher()
    if push:
        push.notify_multiple_devices(
            registration_ids=tokens,
            message_title=titulo,
            message_body=corpo,
            data_message=data or {},
        )


def enviar_para_todos(titulo: str, corpo: str, data: dict = None):
    """Envia push para todos os usuários (alertas de risco)."""
    from apps.accounts.models import Usuario
    tokens = list(
        Usuario.objects.filter(is_active=True)
        .exclude(fcm_token='')
        .values_list('fcm_token', flat=True)
    )
    if not tokens:
        return
    push = _get_pusher()
    if push:
        push.notify_multiple_devices(
            registration_ids=tokens,
            message_title=titulo,
            message_body=corpo,
            data_message=data or {},
        )


def enviar_para_usuario(usuario_id, titulo: str, corpo: str, data: dict = None):
    """Envia push para um usuário específico."""
    from apps.accounts.models import Usuario
    try:
        token = Usuario.objects.get(pk=usuario_id).fcm_token
    except Usuario.DoesNotExist:
        return
    if not token:
        return
    push = _get_pusher()
    if push:
        push.notify_single_device(
            registration_id=token,
            message_title=titulo,
            message_body=corpo,
            data_message=data or {},
        )
