from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Usuario
from .serializers import RegisterSerializer, UsuarioSerializer, UpdateFcmTokenSerializer


class RegisterView(generics.CreateAPIView):
    queryset = Usuario.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UsuarioSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method == 'PATCH' and 'fcm_token' in self.request.data:
            return UpdateFcmTokenSerializer
        return UsuarioSerializer


class AuthoritiesView(generics.ListAPIView):
    """Lista tokens FCM de todas as autoridades — usado pelo servidor para push."""
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Usuario.objects.filter(role='autoridade', is_active=True).exclude(fcm_token='')


class AdminUsersView(generics.ListAPIView):
    """Lista todos os usuários — somente administradores (is_staff=True)."""
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        qs = Usuario.objects.all().order_by('-created_at')
        role = self.request.query_params.get('role')
        if role:
            qs = qs.filter(role=role)
        return qs
