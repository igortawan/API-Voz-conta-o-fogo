from django.db import models
from django.conf import settings


class Verificacao(models.Model):
    ocorrencia = models.ForeignKey(
        'ocorrencias.Ocorrencia', on_delete=models.CASCADE, related_name='verificacoes'
    )
    autoridade = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, related_name='verificacoes'
    )
    resultado = models.CharField(max_length=300)
    observacoes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Verificação'
