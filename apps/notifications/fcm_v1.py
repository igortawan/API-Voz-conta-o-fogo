"""
FCM HTTP v1 API — substitui pyfcm (Legacy API encerrada em junho/2024).

Requer env var FIREBASE_SERVICE_ACCOUNT_JSON com o JSON completo
da Service Account do Firebase (obtido no Firebase Console →
Configurações → Contas de serviço → Gerar nova chave privada).
"""
import json
import requests
from django.conf import settings
from google.oauth2 import service_account
from google.auth.transport.requests import Request as GoogleRequest

_FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'


def _get_token_and_project():
    creds_json = getattr(settings, 'FIREBASE_SERVICE_ACCOUNT_JSON', '')
    if not creds_json:
        return None, None
    info = json.loads(creds_json)
    creds = service_account.Credentials.from_service_account_info(
        info, scopes=[_FCM_SCOPE]
    )
    creds.refresh(GoogleRequest())
    return creds.token, info.get('project_id')


def _send(message: dict):
    token, project_id = _get_token_and_project()
    if not token or not project_id:
        return
    url = f'https://fcm.googleapis.com/v1/projects/{project_id}/messages:send'
    r = requests.post(
        url,
        json={'message': message},
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        },
        timeout=10,
    )
    if r.status_code != 200:
        print(f'[FCM v1] {r.status_code}: {r.text}')


def _android(channel_id='voz_contra_fogo_channel'):
    return {
        'priority': 'high',
        'notification': {'channel_id': channel_id, 'sound': 'default'},
    }


def enviar_para_autoridades(titulo: str, corpo: str, data: dict = None):
    from apps.accounts.models import Usuario
    tokens = list(
        Usuario.objects.filter(role='autoridade', is_active=True)
        .exclude(fcm_token='')
        .values_list('fcm_token', flat=True)
    )
    payload = data or {}
    str_data = {k: str(v) for k, v in payload.items()}
    for fcm_token in tokens:
        _send({
            'token': fcm_token,
            'notification': {'title': titulo, 'body': corpo},
            'data': str_data,
            'android': _android(),
        })


def enviar_para_todos(titulo: str, corpo: str, data: dict = None):
    str_data = {k: str(v) for k, v in (data or {}).items()}
    _send({
        'topic': 'alertas_todos',
        'notification': {'title': titulo, 'body': corpo},
        'data': str_data,
        'android': _android(),
    })


def enviar_para_usuario(usuario_id, titulo: str, corpo: str, data: dict = None):
    from apps.accounts.models import Usuario
    try:
        fcm_token = Usuario.objects.get(pk=usuario_id).fcm_token
    except Usuario.DoesNotExist:
        return
    if not fcm_token:
        return
    str_data = {k: str(v) for k, v in (data or {}).items()}
    _send({
        'token': fcm_token,
        'notification': {'title': titulo, 'body': corpo},
        'data': str_data,
        'android': _android(),
    })
