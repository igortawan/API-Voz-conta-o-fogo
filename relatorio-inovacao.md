# Relatório de Inovação — Voz Contra o Fogo

**Projeto:** API REST de Monitoramento Participativo de Queimadas  
**Equipe:** Igor Tawan Alves dos Santos, Breno Vasconcelos, Jhonatan Mesquita  
**Instituição:** IFPI Campus Paulistana — Iniciação Científica / FAPEPI  
**Data:** 2026-11-03

---

## 1. O Problema

O semiárido piauiense — especialmente os municípios de Paulistana, Jaicós e Acauã — sofre com queimadas recorrentes que destroem a Caatinga e ameaçam comunidades rurais. As denúncias chegam às autoridades (IBAMA, Corpo de Bombeiros) de forma fragmentada, por telefone ou redes sociais, sem estrutura, sem prioridade definida e sem histórico georreferenciado. O resultado é tempo de resposta alto e perda de informação.

---

## 2. APIs Comparadas

| API | O que faz | Limitação |
|-----|-----------|-----------|
| **FireBrigade API** (genérica) | CRUD simples de ocorrências de incêndio | Sem priorização automática; não diferencia urgência entre ocorrências |
| **INPE Queimadas** (dados abertos) | Dados de satélite sobre focos de calor | Dados por satélite, sem participação cidadã; latência de horas; sem feedback para autoridades locais |

---

## 3. O que o Voz Contra o Fogo Faz de Diferente

### 3.1 Score de Prioridade Automático

Nenhuma das APIs comparadas calcula automaticamente a urgência de uma ocorrência. A nossa API aplica uma **regra de negócio própria** no servidor a cada nova denúncia:

```
score = f(nivel_fogo, ha_fumaca, proximo_residencia, latitude, longitude)
```

O score é persistido no banco e usado para ordenar a fila de atendimento das autoridades. Uma ocorrência com `nivel_fogo='critico'`, fumaça visível e próxima a residências recebe prioridade máxima automaticamente — sem intervenção humana.

**Endpoint:** `GET /api/v1/ocorrencias/?ordering=-score_prioridade`  
**Evidência no código:** `apps/ocorrencias/services.py` + `apps/ocorrencias/views.py`

### 3.2 Detecção de Duplicatas Geográficas

Cidadãos diferentes podem reportar o mesmo incêndio. A API detecta denúncias duplicadas por proximidade geográfica antes de criar um novo registro, evitando que a autoridade atenda dois alertas do mesmo foco.

**Endpoint:** `POST /api/v1/ocorrencias/detectar-duplicata/`

### 3.3 Notificação em Tempo Real (WebSocket + FCM)

Ao criar uma ocorrência, a API envia imediatamente:
- **Push notification via FCM** para todos os dispositivos de autoridades cadastradas
- **Broadcast WebSocket** (`/ws/reports/`) para painéis conectados em tempo real

Isso reduz o tempo entre a denúncia e o início do atendimento — diferencial direto para o contexto de brigadas de campo.

---

## 4. Como a Inovação Aparece nos Endpoints

| Eixo de inovação | Endpoint | Mecanismo |
|---|---|---|
| Regra de negócio | `POST /ocorrencias/` | `perform_create` calcula e persiste `score_prioridade` |
| Regra de negócio | `GET /ocorrencias/{id}/score/` | Recalcula e explica o score com recomendação |
| Regra de negócio | `POST /ocorrencias/detectar-duplicata/` | Verifica raio geográfico antes do registro |
| Tempo real | `POST /ocorrencias/` | Dispara FCM + WebSocket group_send |
| Impacto social | Todos | Contexto: Caatinga, semiárido, participação cidadã local |

---

## 5. Conclusão

O Voz Contra o Fogo vai além de um CRUD de ocorrências: ele **processa, prioriza e distribui** as denúncias automaticamente, reduzindo a carga cognitiva das autoridades em campo. O diferencial está na combinação de regra de negócio proprietária (score + duplicatas) com comunicação em tempo real — atributos não encontrados nas APIs públicas comparadas que atuam no mesmo domínio.
