from django.contrib import admin
from .models import Verificacao

@admin.register(Verificacao)
class VerificacaoAdmin(admin.ModelAdmin):
    list_display = ('ocorrencia', 'verificado_por', 'confirmado', 'created_at')
    list_filter = ('confirmado',)
    ordering = ('-created_at',)
