# Sprint 1 — Planning

**Período:** 29/10/2026 a 03/11/2026  
**Scrum Master:** [Integrante 2]  
**Product Owner:** Igor Tawan  

---

## Sprint Goal

> **Um cidadão autenticado consegue registrar uma ocorrência de incêndio e consultá-la com paginação, filtro e ordenação — tudo via `/api/v1/`.**

---

## Capacidade

| Integrante | Disponibilidade (h/dia) | Total da sprint |
|---|---|---|
| Igor Tawan | 3h | ~18h |
| [Integrante 2] | 3h | ~18h |

Estimativa conservadora para a Sprint 1: **15 pontos**

---

## Sprint Backlog

| História (ID) | Tarefas e responsável | Teste derivado dos critérios | Quadrante |
|---|---|---|---|
| H01 — Cadastro de usuário (3 pts) | Implementar `POST /accounts/register/` com validação e retorno de tokens (Igor Tawan) | `test_register_returns_201_with_tokens`, `test_register_duplicate_email_returns_409` | Q1 — testes automatizados que suportam o time |
| H02 — Login e renovação de token (2 pts) | Configurar SimpleJWT, endpoint de login e refresh (Igor Tawan) | `test_login_returns_200_with_tokens`, `test_unauthenticated_access_returns_401` | Q1 |
| H03 — Registrar ocorrência (5 pts) | Model Ocorrencia, serializer, view `POST /ocorrencias/`, cálculo de score na criação ([Integrante 2]) | `test_create_ocorrencia_returns_201`, `test_create_ocorrencia_campo_ausente_returns_400` | Q1 |
| H04 — Listagem com paginação/filtro (3 pts) | Configurar PageNumberPagination, DjangoFilterBackend, OrderingFilter ([Integrante 2]) | `test_list_ocorrencias_returns_200_with_pagination`, `test_filter_by_status` | Q1 |
| H12 — Versionamento `/api/v1/` (2 pts) | Adicionar prefixo `/api/v1/` em `urls.py`, manter `/api/` retroativo (Igor Tawan) | `test_v1_route_accessible`, `test_cache_control_header_present` | Q1 |

**Total: 15 pontos**

---

## Burndown Planejado (Sprint 1)

| Dia da sprint | 1 (29/10) | 2 (30/10) | 3 (31/10) | 4 (01/11) | 5 (02/11) | 6 (03/11) |
|---|---|---|---|---|---|---|
| Pontos restantes (planejado) | 15 | 12 | 9 | 6 | 3 | 0 |
| Pontos restantes (real) | 15 | | | | | |

---

## Regras da Sprint

- O Sprint Goal **não muda** durante a sprint
- Apenas o Product Owner pode trocar uma história por outra de tamanho equivalente
- Cada história só é considerada **Pronta** quando cumpre todos os itens do DoD
