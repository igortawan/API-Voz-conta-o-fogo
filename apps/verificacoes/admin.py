from django.contrib import admin
from .models import Verificacao

@admin.register(Verificacao)
class VerificacaoAdmin(admin.ModelAdmin):
    list_display = ('ocorrencia', 'autoridade', 'resultado', 'created_at')
    search_fields = ('resultado', 'observacoes')
    ordering = ('-created_at',)
