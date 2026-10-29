from django.urls import path
from .views import RecursoListCreateView, RecursoDetailView, disponibilidade_view

urlpatterns = [
    path('', RecursoListCreateView.as_view()),
    path('<int:pk>/', RecursoDetailView.as_view()),
    path('disponibilidade/', disponibilidade_view),
]
