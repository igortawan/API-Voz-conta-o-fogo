from rest_framework import serializers
from .models import Ocorrencia


class OcorrenciaSerializer(serializers.ModelSerializer):
    usuario_nome = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Ocorrencia
        fields = [
            'id', 'usuario', 'usuario_nome', 'anonima',
            'latitude', 'longitude', 'endereco', 'descricao',
            'nivel_fogo', 'nivel_fumaca', 'nivel_risco',
            'ha_fumaca', 'proximo_residencia', 'status',
            'imagens', 'observacoes', 'score_prioridade',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'usuario', 'score_prioridade', 'created_at', 'updated_at']

    def get_usuario_nome(self, obj):
        if obj.anonima or not obj.usuario:
            return 'Anônimo'
        return obj.usuario.nome


class OcorrenciaUpdateSerializer(serializers.ModelSerializer):
    """Usado pelas autoridades para atualizar status e observações."""
    class Meta:
        model = Ocorrencia
        fields = ['status', 'observacoes']


class DuplicataCheckSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    titulo = serializers.CharField(max_length=200)
