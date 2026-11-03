from django.contrib import admin
from .models import Recurso

@admin.register(Recurso)
class RecursoAdmin(admin.ModelAdmin):
    list_display = ('nome', 'tipo', 'disponivel', 'latitude', 'longitude')
    list_filter = ('tipo', 'disponivel')
    search_fields = ('nome',)
