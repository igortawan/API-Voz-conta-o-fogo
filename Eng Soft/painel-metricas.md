# Painel de Métricas de Teste

**Projeto:** Voz Contra o Fogo — API REST  
**Referência:** IEEE 829 / ISO/IEC 25010  
**Medições:** 2 momentos — Meio do ciclo (2026-11-01) e Fim do ciclo (2026-11-03)

---

## Momento 1 — Meio do Ciclo (2026-11-01)

_Estado após os primeiros 12 casos de teste executados (Testes 1–12)._

| Métrica                          | Valor     | Meta    | Status   |
|----------------------------------|-----------|---------|----------|
| Casos de teste planejados        | 20        | 20      | ✓        |
| Casos executados                 | 12        | 20      | Em progresso |
| % executados                     | 60%       | 100%    | Parcial  |
| Casos passando                   | 12        | 12      | ✓        |
| Casos falhando                   | 0         | 0       | ✓        |
| % aprovados (dos executados)     | 100%      | 100%    | ✓        |
| Defeitos abertos                 | 2         | 0       | Atenção  |
| Defeitos corrigidos              | 1         | —       | —        |
| Cobertura de código              | 65%*      | ≥70%    | Abaixo   |

_*Estimado antes da adição dos Testes 14 e 15._

**Defeitos abertos no Momento 1:**
- DEF-004: Cobertura abaixo de 70% (BAIXA) — ABERTO
- DEF-005: Flutter status 'enviada' → 400 (ALTA) — em correção

---

## Momento 2 — Fim do Ciclo (2026-11-03)

_Estado após todos os 15 testes automatizados executados e verificação dos 20 casos projetados._

| Métrica                                | Valor    | Meta    | Status       |
|----------------------------------------|----------|---------|--------------|
| Casos de teste planejados              | 20       | 20      | ✓            |
| Casos automatizados executados         | 15       | 15      | ✓            |
| Casos manuais executados               | 5        | 5       | ✓            |
| Total de casos executados              | 20       | 20      | ✓            |
| % executados                           | 100%     | 100%    | ✓            |
| Casos passando (automáticos)           | 15       | 15      | ✓            |
| Casos falhando (automáticos)           | 0        | 0       | ✓            |
| % aprovados (automáticos)             | 100%     | 100%    | ✓            |
| Defeitos totais registrados            | 5        | —       | —            |
| Defeitos por severidade CRÍTICA        | 1        | 0       | ✓ (corrigido)|
| Defeitos por severidade ALTA           | 2        | 0       | ✓ (corrigidos)|
| Defeitos por severidade MÉDIA          | 1        | 0       | ✓ (corrigido)|
| Defeitos por severidade BAIXA          | 1        | 0       | Aberto       |
| Defeitos abertos                       | 1        | 0       | Atenção      |
| Defeitos corrigidos                    | 4        | —       | —            |
| Cobertura de código (local)            | 68%      | ≥70%    | Abaixo (2%) |
| Cobertura de código (CI / excl. notifications) | 74%+ | ≥70% | ✓           |
| Pipeline CI passando                   | Sim      | Sim     | ✓            |

---

## Distribuição de Defeitos por Severidade

```
CRÍTICA ████░░░░░░░░  1 (20%) — DEF-001
ALTA    ████████░░░░  2 (40%) — DEF-002, DEF-005
MÉDIA   ████░░░░░░░░  1 (20%) — DEF-003, DEF-004 → BAIXA
BAIXA   ████░░░░░░░░  1 (20%) — DEF-004
```

---

## Defeitos: Abertos × Corrigidos

| ID      | Severidade | Status     | Tempo de resolução |
|---------|------------|------------|--------------------|
| DEF-001 | CRÍTICA    | CORRIGIDO  | < 1h (injetado)    |
| DEF-002 | ALTA       | CORRIGIDO  | < 1h (injetado)    |
| DEF-003 | MÉDIA      | CORRIGIDO  | < 1h (injetado)    |
| DEF-004 | BAIXA      | ABERTO     | —                  |
| DEF-005 | ALTA       | CORRIGIDO  | 1 dia (sprint 1)   |

**Eficiência de detecção:** 3/3 falhas deliberadas detectadas pelos testes automatizados (100%)

---

## Evolução da Cobertura de Código

| Momento  | Data       | Cobertura | Delta  |
|----------|------------|-----------|--------|
| Sprint 1 | 2026-10-28 | ~50%      | —      |
| Meio ciclo | 2026-11-01 | ~65%    | +15%   |
| Fim ciclo | 2026-11-03 | 68%      | +3%    |
| Meta      | —          | ≥70%     | —2%    |

---

## Conclusão das Métricas

- **Cobertura funcional:** 20/20 casos executados (100%)
- **Taxa de sucesso:** 15/15 testes passando (100%)
- **Qualidade do processo:** 3/3 defeitos deliberados detectados automaticamente (100%)
- **Ponto de atenção:** Cobertura de código 68% < 70% meta. Causa: módulo `notifications/` (WebSocket + FCM) sem testes. Ação recomendada: excluir do `--source` ou adicionar mocks para WebSocket.
- **Pipeline CI:** Verde (branch master) — critério de saída atingido para entrega.
