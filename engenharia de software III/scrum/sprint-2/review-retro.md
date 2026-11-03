# Sprint 2 — Review e Retrospectiva

**Data:** 08/11/2026  
**Scrum Master:** Igor Tawan  
**Product Owner:** Igor Tawan  

---

## Sprint Review

**Sprint Goal:** *"A API entrega score de prioridade automático, atualização de status por autoridade, exclusão de ocorrências, documentação OpenAPI completa e 15+ testes automatizados com 70% de cobertura rodando em CI."*

### Histórias demonstradas ao Product Owner

| História | Status | Aceita? | Observação |
|---|---|---|---|
| H05 — Score de prioridade automático | ✅ Pronta | Sim | `GET /ocorrencias/{id}/score/` retorna 200; score > 80 para incêndios críticos |
| H07 — Atualizar status de ocorrência | ✅ Pronta | Sim | Cidadão recebe 403; autoridade recebe 200 — demonstrado via Swagger |
| H08 — Excluir ocorrência | ✅ Pronta | Sim | DELETE retorna 204; 404 para id inexistente |
| H13 — Documentação OpenAPI e README | ✅ Pronta | Sim | `/api/v1/docs/` com todos os endpoints; README seguido pelo PO sem ajuda |
| H14 — Suíte de testes automatizados | ✅ Pronta | Sim | 15 testes, 74% de cobertura, CI verde no GitHub Actions |

**Incremento entregue:** 21 pontos. Sprint Goal 100% cumprido.

### Backlog final após a Review
- H06 (Detecção de duplicata) permanece no backlog — *não priorizada neste ciclo*
- H09 (Alertas), H10 (Recursos), H11 (Verificações) — backlog para possível Sprint 3 ou manutenção futura

---

## Retrospectiva

### O que a equipe deve...

| Começar a fazer | Parar de fazer | Continuar fazendo |
|---|---|---|
| Escrever o DoD explicitamente no corpo do PR antes de abrir | Acumular o burndown para atualizar de uma vez no final do dia | TDD: escrever o teste que falha antes de implementar |
| Adicionar badge de CI ao README para visibilidade | Mergear PR sem ao menos um comentário de revisão | Pair review antes do merge |
| Documentar decisões de design em comentários curtos no código | — | Daily por escrito no WhatsApp às 20h |

### Melhoria escolhida (registro para documentação)

| Melhoria | Responsável | Prazo | Funcionou? |
|---|---|---|---|
| TDD — adotado desde o dia 1 da Sprint 2 (melhoria da Retro Sprint 1) | Igor Tawan | 05/11/2026 | ✅ Sim — H08 foi implementada com teste escrito primeiro, zero regressões nos outros testes |

### As 3 perguntas obrigatórias da Retrospectiva

**1. A velocidade da Sprint 2 foi maior que a da Sprint 1? Por quê?**  
Sim. A velocidade subiu de 15 pontos (Sprint 1) para 21 pontos (Sprint 2) — aumento de 40%. Os dois fatores principais foram: (a) a equipe já conhecia o código e o ambiente, eliminando o overhead de setup que existiu na Sprint 1; e (b) a adoção do TDD reduziu o tempo de debug — ao escrever o teste antes do código, o comportamento esperado já estava claro, e o ciclo de red→green foi mais direto do que a abordagem de "implementa e depois testa" da Sprint 1.

**2. Qual história ficou incompleta? Que critério de aceitação ou item da DoD faltou?**  
H06 (Detecção de duplicatas geográficas) ficou incompleta e permanece no backlog. O critério de aceitação não atendido foi: *"Dado que já existe uma ocorrência a menos de 500m, quando um segundo cidadão reporta outra ocorrência no mesmo raio, então o endpoint `/detectar-duplicata/` retorna `is_duplicata=true` com referência ao ID original."* A história não entrou na Sprint 2 porque a estimativa de 5 pontos, combinada com as 5 histórias já planejadas (21 pontos), excederia a capacidade da equipe. O item do DoD que teria sido exigido e não foi verificado é o item 2: *"cobertura ≥ 70% após a adição da funcionalidade"* — a lógica de raio geográfico adicionaria complexidade ao `services.py` que demandaria testes de integração extras para manter a cobertura.

**3. A melhoria adotada na Retro 1 (TDD) funcionou? Evidência nos commits.**  
Sim. A melhoria foi: *"adotar TDD a partir do dia 1 da Sprint 2"*. Evidência nos commits:  
- [`b4cdd48`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/b4cdd48): mensagem `test(ci): adicionar pipeline GitHub Actions e elevar suite para 15 testes` — os testes 14 e 15 (TDD) foram o gatilho para o CI pipeline ser configurado, não o contrário.  
- Histórico da Daily 3 (01/11): *"H08 testes escritos ANTES da view"* — o teste estava no repositório antes do commit da implementação, comprovando o ciclo Red (teste falhando) → Green (implementação mínima) → Refactor.  
- Zero regressões no sprint 2: todos os 15 testes passaram em cada push, sem rollback.

---

## Resultado final do projeto

| Métrica | Resultado |
|---|---|
| Velocidade Sprint 1 | 15 pontos |
| Velocidade Sprint 2 | 21 pontos |
| Total de histórias entregues | 10 de 14 (H01–H05, H07–H08, H12–H14) |
| Cobertura de testes | 74% |
| Testes automatizados | 15 |
| CI pipeline | ✅ GitHub Actions |
| Documentação OpenAPI | ✅ `/api/v1/docs/` |
