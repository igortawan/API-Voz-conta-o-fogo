from rest_framework import generics, permissions
from .models import Verificacao
from .serializers import VerificacaoSerializer


class IsAuthoridade(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.role == 'autoridade'


class VerificacaoListCreateView(generics.ListCreateAPIView):
    serializer_class = VerificacaoSerializer
    permission_classes = [IsAuthoridade]

    def get_queryset(self):
        qs = Verificacao.objects.all()
        ocorrencia_id = self.request.query_params.get('ocorrencia')
        if ocorrencia_id:
            qs = qs.filter(ocorrencia_id=ocorrencia_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(autoridade=self.request.user)
