"""
Testes de integração — Voz Contra o Fogo API
Cobre todos os recursos principais com pelo menos 10 casos de teste.
"""
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from apps.accounts.models import Usuario
from apps.ocorrencias.models import Ocorrencia
from apps.alertas.models import Alerta


def make_user(email='cidadao@test.com', role='cidadao', password='Senha@123'):
    return Usuario.objects.create_user(email=email, nome='Teste', password=password, role=role)


def make_autoridade(email='auto@test.com', password='Senha@123'):
    return make_user(email=email, role='autoridade', password=password)


def token_for(client, email, password='Senha@123'):
    res = client.post('/api/v1/accounts/login/', {'email': email, 'password': password})
    return res.data.get('access', '')


def auth(client, email, password='Senha@123'):
    t = token_for(client, email, password)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {t}')


OCORRENCIA_BASE = {
    'latitude': '-7.934',
    'longitude': '-40.501',
    'descricao': 'Fogo avistado na fazenda',
    'nivel_fogo': 'medio',
    'nivel_fumaca': 'medio',
    'nivel_risco': 'medio',
    'ha_fumaca': True,
    'proximo_residencia': False,
    'anonima': False,
}


class AuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    # Teste 1
    def test_register_returns_201_with_tokens(self):
        res = self.client.post('/api/v1/accounts/register/', {
            'email': 'novo@test.com', 'nome': 'Novo', 'password': 'Senha@123', 'role': 'cidadao',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)

    # Teste 2
    def test_register_duplicate_email_returns_409(self):
        make_user()
        res = self.client.post('/api/v1/accounts/register/', {
            'email': 'cidadao@test.com', 'nome': 'X', 'password': 'Senha@123',
        })
        self.assertEqual(res.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(res.data['code'], 'email_conflict')

    # Teste 3
    def test_login_returns_200_with_tokens(self):
        make_user()
        res = self.client.post('/api/v1/accounts/login/', {
            'email': 'cidadao@test.com', 'password': 'Senha@123',
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)

    # Teste 4
    def test_unauthenticated_access_returns_401(self):
        res = self.client.get('/api/v1/ocorrencias/')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(res.data['code'], 'unauthorized')

    # Teste 5
    def test_me_returns_user_data(self):
        make_user()
        auth(self.client, 'cidadao@test.com')
        res = self.client.get('/api/v1/accounts/me/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['email'], 'cidadao@test.com')


class OcorrenciaTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.cidadao = make_user()
        self.autoridade = make_autoridade()

    # Teste 6
    def test_create_ocorrencia_returns_201(self):
        auth(self.client, 'cidadao@test.com')
        res = self.client.post('/api/v1/ocorrencias/', OCORRENCIA_BASE, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', res.data)

    # Teste 7
    def test_list_ocorrencias_returns_200_with_pagination(self):
        Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.9', longitude='-40.5',
            nivel_fogo='baixo', score_prioridade=10,
        )
        auth(self.client, 'cidadao@test.com')
        res = self.client.get('/api/v1/ocorrencias/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('results', res.data)
        self.assertIn('Cache-Control', res)

    # Teste 8
    def test_autoridade_can_update_status(self):
        oc = Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.9', longitude='-40.5',
            nivel_fogo='alto', score_prioridade=80,
        )
        auth(self.client, 'auto@test.com')
        res = self.client.patch(f'/api/v1/ocorrencias/{oc.id}/', {'status': 'em_analise'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        oc.refresh_from_db()
        self.assertEqual(oc.status, 'em_analise')

    # Teste 9
    def test_cidadao_cannot_update_status(self):
        oc = Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.9', longitude='-40.5',
            nivel_fogo='alto', score_prioridade=80,
        )
        auth(self.client, 'cidadao@test.com')
        res = self.client.patch(f'/api/v1/ocorrencias/{oc.id}/', {'status': 'atendida'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # Teste 10
    def test_autoridade_can_delete_ocorrencia(self):
        oc = Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.9', longitude='-40.5',
            nivel_fogo='baixo', score_prioridade=10,
        )
        auth(self.client, 'auto@test.com')
        res = self.client.delete(f'/api/v1/ocorrencias/{oc.id}/')
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Ocorrencia.objects.filter(id=oc.id).exists())

    # Teste 11
    def test_score_endpoint_returns_score(self):
        oc = Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.934', longitude='-40.501',
            nivel_fogo='alto', ha_fumaca=True, proximo_residencia=True, score_prioridade=90,
        )
        auth(self.client, 'cidadao@test.com')
        res = self.client.get(f'/api/v1/ocorrencias/{oc.id}/score/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('score', res.data)
        self.assertIn('recomendacao', res.data)

    # Teste 12
    def test_filter_by_status(self):
        Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.9', longitude='-40.5',
            nivel_fogo='baixo', status='pendente', score_prioridade=10,
        )
        Ocorrencia.objects.create(
            usuario=self.cidadao, latitude='-7.8', longitude='-40.4',
            nivel_fogo='alto', status='atendida', score_prioridade=80,
        )
        auth(self.client, 'cidadao@test.com')
        res = self.client.get('/api/v1/ocorrencias/?status=pendente')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        for item in res.data['results']:
            self.assertEqual(item['status'], 'pendente')

    # Teste 13
    def test_ocorrencia_not_found_returns_404(self):
        import uuid
        auth(self.client, 'cidadao@test.com')
        res = self.client.get(f'/api/v1/ocorrencias/{uuid.uuid4()}/')
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(res.data['code'], 'not_found')
