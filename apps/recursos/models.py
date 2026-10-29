from django.db import models


class RecursoCombate(models.Model):
    TIPO = [('caminhao_pipa', 'Caminhão-Pipa'), ('brigada', 'Brigada'), ('equipamento', 'Equipamento')]

    nome = models.CharField(max_length=200)
    tipo = models.CharField(max_length=20, choices=TIPO)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    disponivel = models.BooleanField(default=True)
    capacidade = models.CharField(max_length=100, blank=True)
    descricao = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['nome']
        verbose_name = 'Recurso de Combate'
