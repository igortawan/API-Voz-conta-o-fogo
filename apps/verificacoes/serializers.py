from rest_framework import serializers
from .models import Verificacao


class VerificacaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Verificacao
        fields = '__all__'
        read_only_fields = ['id', 'autoridade', 'created_at']
