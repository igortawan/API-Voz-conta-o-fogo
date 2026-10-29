from django.urls import path
from .views import AlertaListCreateView, AlertaDetailView

urlpatterns = [
    path('', AlertaListCreateView.as_view()),
    path('<int:pk>/', AlertaDetailView.as_view()),
]
