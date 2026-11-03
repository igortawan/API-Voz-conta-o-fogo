from django.contrib import admin
from .models import Alerta

@admin.register(Alerta)
class AlertaAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'nivel_risco', 'ativo', 'emitido_por', 'created_at')
    list_filter = ('nivel_risco', 'ativo')
    search_fields = ('titulo', 'descricao')
    ordering = ('-created_at',)
