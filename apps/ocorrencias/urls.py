from django.urls import path
from .views import OcorrenciaListCreateView, OcorrenciaDetailView, score_view, duplicata_view

urlpatterns = [
    path('', OcorrenciaListCreateView.as_view()),
    path('<uuid:pk>/', OcorrenciaDetailView.as_view()),
    path('<uuid:pk>/score/', score_view),
    path('detectar-duplicata/', duplicata_view),
]
