from django.contrib import admin
from .models import Ocorrencia

@admin.register(Ocorrencia)
class OcorrenciaAdmin(admin.ModelAdmin):
    list_display = ('id', 'nivel_fogo', 'status', 'score_prioridade', 'anonima', 'usuario', 'created_at')
    list_filter = ('status', 'nivel_fogo', 'anonima')
    search_fields = ('descricao', 'endereco')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'created_at', 'updated_at', 'score_prioridade')
