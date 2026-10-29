from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import Usuario


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = Usuario
        fields = ['email', 'nome', 'password', 'role']

    def create(self, validated_data):
        return Usuario.objects.create_user(**validated_data)


class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'email', 'nome', 'role', 'fcm_token', 'created_at']
        read_only_fields = ['id', 'email', 'role', 'created_at']


class UpdateFcmTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['fcm_token']


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not Usuario.objects.filter(email=value, is_active=True).exists():
            raise serializers.ValidationError('Nenhuma conta encontrada com este e-mail.')
        return value
