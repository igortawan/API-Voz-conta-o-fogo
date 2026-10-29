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

**1. O que a equipe fez bem nesta sprint?**  
A equipe manteve o ritmo consistente: nenhum dia terminou com o burndown acima do planejado. A adoção do TDD reduziu o tempo de debug em H08 e H05 — os testes escritos antes já documentavam o comportamento esperado, facilitando a revisão de código.

**2. O que pode melhorar para a próxima sprint ou projeto?**  
O burndown foi atualizado de forma irregular (acumulado no final do dia em vez de ao longo do dia). Embora não tenha impactado a entrega, criou momentos de incerteza sobre o progresso real. A melhoria é simples: atualizar o burndown ao completar cada tarefa, não ao final do dia.

**3. Qual ação concreta a equipe se compromete a adotar imediatamente?**  
Adicionar o badge do CI ao README e incluir o DoD checklist no template de PR — duas mudanças de 5 minutos que tornam a "Pronto" visível sem precisar perguntar ao Scrum Master.

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
