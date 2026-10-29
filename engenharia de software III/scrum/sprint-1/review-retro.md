# Sprint 1 — Review e Retrospectiva

**Data:** 03/11/2026  
**Scrum Master:** [Integrante 2]  
**Product Owner:** Igor Tawan  

---

## Sprint Review

**Sprint Goal:** *"Um cidadão autenticado consegue registrar uma ocorrência de incêndio e consultá-la com paginação, filtro e ordenação — tudo via `/api/v1/`."*

### Histórias demonstradas ao Product Owner

| História | Status | Aceita? | Observação |
|---|---|---|---|
| H01 — Cadastro de usuário | ✅ Pronta | Sim | Demonstrada via Swagger: 201 e 409 funcionando |
| H02 — Login e renovação de token | ✅ Pronta | Sim | Access token retornado, refresh funcionando |
| H03 — Registrar ocorrência | ✅ Pronta | Sim | score_prioridade calculado no servidor |
| H04 — Listagem com paginação/filtro | ✅ Pronta | Sim | `?status=pendente&ordering=-score_prioridade` funciona |
| H12 — Versionamento `/api/v1/` | ✅ Pronta | Sim | Cache-Control presente na resposta |

**Incremento entregue:** todos os 15 pontos planejados estão prontos.

### Backlog atualizado após a Review
- H05 (Score — 8 pts) permanece como prioridade máxima para a Sprint 2
- H10 (Recursos) e H11 (Verificações) rebaixados para "Could" — priorizados H13 e H14

---

## Retrospectiva

### O que a equipe deve...

| Começar a fazer | Parar de fazer | Continuar fazendo |
|---|---|---|
| Abrir PRs menores (máx. 1 história por PR) | Commitar diretamente comentando "pequena mudança" | Daily por escrito no WhatsApp |
| Escrever testes **antes** do código (TDD) | Deixar a revisão do PR para o último dia | Nomear a história no título do commit (#ID) |
| Registrar o burndown todo dia, não acumular | — | Revisar o código em par antes do PR |

### Melhoria escolhida para a Sprint 2

| Melhoria | Responsável | Prazo | Funcionou? |
|---|---|---|---|
| Adotar TDD: escrever o teste que falha antes de implementar qualquer endpoint | Igor Tawan | 05/11/2026 | *(avaliar na Retro 2)* |

> Esta melhoria entra como item no Sprint Backlog da Sprint 2.
