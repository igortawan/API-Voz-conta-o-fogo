from django.db import models
from django.conf import settings


class Alerta(models.Model):
    NIVEL = [('baixo', 'Baixo'), ('medio', 'Médio'), ('alto', 'Alto'), ('critico', 'Crítico')]

    titulo = models.CharField(max_length=300)
    descricao = models.TextField()
    nivel_risco = models.CharField(max_length=10, choices=NIVEL)
    autoridade = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, related_name='alertas'
    )
    vigente = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Alerta'
