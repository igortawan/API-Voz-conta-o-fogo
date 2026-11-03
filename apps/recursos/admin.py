from django.contrib import admin
from .models import RecursoCombate

@admin.register(RecursoCombate)
class RecursoCombateAdmin(admin.ModelAdmin):
    list_display = ('nome', 'tipo', 'disponivel', 'latitude', 'longitude')
    list_filter = ('tipo', 'disponivel')
    search_fields = ('nome',)
