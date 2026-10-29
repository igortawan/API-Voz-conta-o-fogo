# Sprint 2 — Planning

**Período:** 04/11/2026 a 08/11/2026  
**Scrum Master:** Igor Tawan  
**Product Owner:** Igor Tawan  

---

## Sprint Goal

> **A API entrega score de prioridade automático, atualização de status por autoridade, exclusão de ocorrências, documentação OpenAPI completa e 15+ testes automatizados com 70% de cobertura rodando em CI.**

---

## Capacidade

| Integrante | Disponibilidade (h/dia) | Total da sprint |
|---|---|---|
| Igor Tawan | 4h | ~20h |
| [Integrante 2] | 3h | ~15h |

Estimativa conservadora para a Sprint 2: **24 pontos**

---

## Sprint Backlog

| História (ID) | Tarefas e responsável | Teste derivado dos critérios | Quadrante |
|---|---|---|---|
| H05 — Score de prioridade automático (8 pts) | Lógica de score no model/serializer, endpoint `GET /ocorrencias/{id}/score/` (Igor Tawan) | `test_score_returned_on_create`, `test_score_endpoint_returns_200` | Q1 — testes automatizados que suportam o time |
| H07 — Atualizar status de ocorrência (3 pts) | Restrição por papel em `PATCH /ocorrencias/{id}/`, permissão `IsAutoridade` ([Integrante 2]) | `test_autoridade_updates_status_200`, `test_cidadao_cannot_update_403` | Q1 |
| H08 — Excluir ocorrência (2 pts) | Método DELETE em `RetrieveUpdateDestroyAPIView`, retorno 204 (Igor Tawan) | `test_autoridade_deletes_204`, `test_delete_not_found_404` | Q1 |
| H13 — Documentação OpenAPI e README (3 pts) | `drf-spectacular`, `/api/v1/docs/`, README com instruções de instalação ([Integrante 2]) | `test_swagger_ui_accessible`, verificação manual do README | Q2 — testes que validam o produto |
| H14 — Suíte de testes (5 pts) | 15+ testes, cobertura ≥ 70%, GitHub Actions CI pipeline (Igor Tawan) | `test_*` todos passando no CI, badge no README | Q1 |
| H09 — Alertas (3 pts) — *se capacidade permitir* | `POST /alertas/`, restrição por papel | `test_autoridade_creates_alert_201`, `test_cidadao_forbidden_403` | Q1 |

**Total comprometido (sem H09): 21 pontos**

---

## Burndown Planejado (Sprint 2)

| Dia da sprint | 1 (04/11) | 2 (05/11) | 3 (06/11) | 4 (07/11) | 5 (08/11) |
|---|---|---|---|---|---|
| Pontos restantes (planejado) | 21 | 17 | 12 | 7 | 0 |
| Pontos restantes (real) | 21 | | | | |

---

## Melhoria da Retrospectiva Sprint 1

> **TDD**: escrever o teste que falha antes de implementar o endpoint.  
> Responsável: Igor Tawan. Prazo: 05/11/2026.

---

## Regras da Sprint

- Sprint Goal **não muda** durante a sprint
- H09 entra apenas se H14 for concluída antes do dia 07/11
- Apenas o Product Owner pode trocar uma história por outra de tamanho equivalente
