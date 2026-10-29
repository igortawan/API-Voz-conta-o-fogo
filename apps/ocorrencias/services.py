import math
from datetime import timedelta
from django.utils import timezone


# ── Score de prioridade ───────────────────────────────────────────────────────

SCORE_RULES = {
    'critico': 40, 'alto': 25, 'medio': 12, 'baixo': 5,
}

def calcular_score(nivel_fogo: str, ha_fumaca: bool, proximo_residencia: bool,
                   latitude: float, longitude: float) -> dict:
    score = SCORE_RULES.get(nivel_fogo, 5)
    if ha_fumaca:
        score += 20
    if proximo_residencia:
        score += 15
    if latitude != 0 and longitude != 0:
        score += 10
    score = min(score, 100)

    if score >= 80:
        nivel, recomendacao = 'CRÍTICO', 'Acionar brigada imediatamente'
    elif score >= 60:
        nivel, recomendacao = 'ALTO', 'Enviar equipe de vistoria urgente'
    elif score >= 40:
        nivel, recomendacao = 'MÉDIO', 'Monitorar e preparar equipe'
    else:
        nivel, recomendacao = 'BAIXO', 'Registrar e acompanhar evolução'

    return {'score': score, 'nivel': nivel, 'recomendacao': recomendacao}


# ── Detecção de duplicatas ────────────────────────────────────────────────────

def _haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _similaridade_texto(a: str, b: str) -> float:
    a_words = set(a.lower().split())
    b_words = set(b.lower().split())
    if not a_words or not b_words:
        return 0.0
    return len(a_words & b_words) / len(a_words | b_words)


def detectar_duplicata(latitude: float, longitude: float, titulo: str,
                       raio_km: float = 0.5, horas: int = 24) -> dict:
    from .models import Ocorrencia
    desde = timezone.now() - timedelta(hours=horas)
    recentes = Ocorrencia.objects.filter(created_at__gte=desde)

    melhor_confianca = 0.0
    for oc in recentes:
        dist = _haversine_km(latitude, longitude, float(oc.latitude), float(oc.longitude))
        if dist > raio_km:
            continue
        sim_texto = _similaridade_texto(titulo, oc.descricao[:50])
        # Distância mais próxima = maior peso; texto complementar
        geo_score = max(0, 1 - (dist / raio_km))
        confianca = (geo_score * 0.7) + (sim_texto * 0.3)
        melhor_confianca = max(melhor_confianca, confianca)

    return {
        'is_duplicate': melhor_confianca >= 0.7,
        'confianca': round(melhor_confianca, 2),
    }
