from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('apps.accounts.urls')),
    path('api/ocorrencias/', include('apps.ocorrencias.urls')),
    path('api/recursos/', include('apps.recursos.urls')),
    path('api/alertas/', include('apps.alertas.urls')),
    path('api/verificacoes/', include('apps.verificacoes.urls')),
]
