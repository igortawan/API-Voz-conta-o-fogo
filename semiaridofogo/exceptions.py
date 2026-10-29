from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is None:
        return Response(
            {'code': 'server_error', 'message': 'Erro interno do servidor.', 'details': {}},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    status_code = response.status_code
    data = response.data

    code_map = {
        400: 'bad_request',
        401: 'unauthorized',
        403: 'forbidden',
        404: 'not_found',
        405: 'method_not_allowed',
        409: 'conflict',
        429: 'throttled',
    }

    if isinstance(data, dict) and 'code' in data:
        return response

    details = {}
    message = 'Erro na requisição.'

    if isinstance(data, dict):
        if 'detail' in data:
            message = str(data['detail'])
        else:
            details = {k: v if isinstance(v, list) else [v] for k, v in data.items()}
            first = next(iter(details.values()), [message])
            message = str(first[0]) if first else message
    elif isinstance(data, list):
        message = str(data[0]) if data else message

    response.data = {
        'code': code_map.get(status_code, 'error'),
        'message': message,
        'details': details,
    }
    return response
