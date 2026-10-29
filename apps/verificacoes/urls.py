from django.urls import path
from .views import VerificacaoListCreateView

urlpatterns = [
    path('', VerificacaoListCreateView.as_view()),
]
