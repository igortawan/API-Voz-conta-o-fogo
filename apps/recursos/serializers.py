from rest_framework import serializers
from .models import RecursoCombate


class RecursoSerializer(serializers.ModelSerializer):
    distancia_km = serializers.SerializerMethodField()

    class Meta:
        model = RecursoCombate
        fields = '__all__'

    def get_distancia_km(self, obj):
        return self.context.get('distancias', {}).get(obj.id)
