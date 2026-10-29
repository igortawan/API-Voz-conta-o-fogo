from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

# Rotas versionadas (v1) — padrão para avaliação e novos clientes
v1_patterns = [
    path('accounts/', include('apps.accounts.urls')),
    path('ocorrencias/', include('apps.ocorrencias.urls')),
    path('recursos/', include('apps.recursos.urls')),
    path('alertas/', include('apps.alertas.urls')),
    path('verificacoes/', include('apps.verificacoes.urls')),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    # OpenAPI / Swagger
    path('api/v1/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/v1/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/v1/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    # /api/v1/ — versão atual
    path('api/v1/', include(v1_patterns)),
    # /api/ — mantido para compatibilidade retroativa com o app Flutter
    path('api/accounts/', include('apps.accounts.urls')),
    path('api/ocorrencias/', include('apps.ocorrencias.urls')),
    path('api/recursos/', include('apps.recursos.urls')),
    path('api/alertas/', include('apps.alertas.urls')),
    path('api/verificacoes/', include('apps.verificacoes.urls')),
]
