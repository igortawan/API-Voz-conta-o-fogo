import uuid
from django.db import models
from django.conf import settings


class Ocorrencia(models.Model):
    STATUS = [('pendente', 'Pendente'), ('em_analise', 'Em Análise'), ('atendida', 'Atendida')]
    NIVEL_FOGO = [('baixo', 'Baixo'), ('medio', 'Médio'), ('alto', 'Alto'), ('critico', 'Crítico')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='ocorrencias'
    )
    anonima = models.BooleanField(default=False)
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    endereco = models.CharField(max_length=500, blank=True, default='')
    descricao = models.TextField(blank=True, default='')
    nivel_fogo = models.CharField(max_length=10, choices=NIVEL_FOGO)
    nivel_fumaca = models.CharField(max_length=50, default='')
    nivel_risco = models.CharField(max_length=50, default='')
    ha_fumaca = models.BooleanField(default=False)
    proximo_residencia = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=STATUS, default='pendente')
    imagens = models.JSONField(default=list)
    observacoes = models.TextField(blank=True, default='')
    score_prioridade = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Ocorrência'

    def __str__(self):
        return f'{self.nivel_fogo} — {self.latitude},{self.longitude}'
