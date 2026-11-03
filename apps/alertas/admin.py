from django.contrib import admin
from .models import Alerta

@admin.register(Alerta)
class AlertaAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'nivel_risco', 'vigente', 'autoridade', 'created_at')
    list_filter = ('nivel_risco', 'vigente')
    search_fields = ('titulo', 'descricao')
    ordering = ('-created_at',)
