import math
from rest_framework import generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import RecursoCombate
from .serializers import RecursoSerializer


def _haversine(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class RecursoListCreateView(generics.ListCreateAPIView):
    queryset = RecursoCombate.objects.all()
    serializer_class = RecursoSerializer
    permission_classes = [permissions.IsAuthenticated]


class RecursoDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = RecursoCombate.objects.all()
    serializer_class = RecursoSerializer
    permission_classes = [permissions.IsAuthenticated]


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def disponibilidade_view(request):
    lat = float(request.query_params.get('lat', 0))
    lng = float(request.query_params.get('lng', 0))
    raio = float(request.query_params.get('raio', 50))

    recursos = RecursoCombate.objects.filter(disponivel=True, latitude__isnull=False)
    distancias = {}
    dentro = []
    for r in recursos:
        d = _haversine(lat, lng, float(r.latitude), float(r.longitude))
        if d <= raio:
            distancias[r.id] = round(d, 2)
            dentro.append(r)

    dentro.sort(key=lambda r: distancias[r.id])
    serializer = RecursoSerializer(dentro, many=True, context={'distancias': distancias})
    return Response(serializer.data)
