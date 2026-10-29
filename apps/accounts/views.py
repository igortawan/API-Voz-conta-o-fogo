from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from .models import Usuario
from .serializers import RegisterSerializer, UsuarioSerializer, UpdateFcmTokenSerializer, PasswordResetSerializer


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


class PasswordResetView(APIView):
    """Recuperação de senha — gera nova senha temporária e retorna ao usuário."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        user = Usuario.objects.get(email=email)

        import secrets, string
        nova_senha = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(10))
        user.set_password(nova_senha)
        user.save(update_fields=['password'])

        response_data = {'detail': 'Nova senha gerada com sucesso.'}
        from django.conf import settings as dj_settings
        if dj_settings.DEBUG:
            response_data['nova_senha'] = nova_senha

        return Response(response_data, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """Invalida o refresh token, impedindo renovação futura do access token."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'detail': 'Refresh token obrigatório.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'detail': 'Logout realizado com sucesso.'}, status=status.HTTP_200_OK)
        except TokenError:
            return Response({'detail': 'Token inválido ou já expirado.'}, status=status.HTTP_400_BAD_REQUEST)


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
