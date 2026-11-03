# Relato Individual — Leonardo Arrais

**Papel:** Desenvolvedor · Documentação Scrum · Apoio em Testes  
**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas

---

## 1. Três contribuições com evidência

### Contribuição 1 — Documentação completa das Sprints (planning, dailies, review-retro)

Redigi e organizei todos os artefatos Scrum das duas sprints: planning.md, dailies.md e review-retro.md para Sprint 1 e Sprint 2. Isso incluiu transcrever os registros das dailies realizadas às 16h por WhatsApp, consolidar o burndown com base nos pontos reportados pela equipe e estruturar a retrospectiva com o formato começar/parar/continuar exigido pela atividade.

**Evidência no commit:**  
[`86ff0a9`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/86ff0a9) — `docs(scrum): adicionar documentação completa das sprints 1 e 2`

---

### Contribuição 2 — Plano de testes (Fase 1 do processo de testes)

Elaborei o plano de testes da API cobrindo escopo, abordagem, critérios de entrada/saída, papéis e responsabilidades, e ambientes. O plano foi a base para as fases seguintes do processo de testes exigido pela atividade de Engenharia de Software.

**Evidência no commit:**  
[`7cb37fd`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/7cb37fd) — `Adiciona plano de testes (Fase 1)`

---

### Contribuição 3 — Casos de teste e matriz de rastreabilidade (Fase 2)

Criei os 20 casos de teste mapeando cada história de usuário a cenários positivos e negativos, com pré-condições, passos e resultado esperado. Elaborei também a matriz de rastreabilidade ligando cada caso de teste ao requisito correspondente no backlog.

**Evidência no commit:**  
[`f8272b5`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/f8272b5) — `Adiciona casos de teste e matriz de rastreabilidade (Fase 2)`

---

## 2. Uma decisão em que o Scrum mudou o que eu faria

Durante a **Review da Sprint 1**, demonstramos as 5 histórias ao Product Owner (Igor, no papel de representante dos parceiros). A H04 (paginação e filtro) foi aceita, mas o PO sinalizou que o filtro por `municipio` era mais relevante para as autoridades do que o filtro por `status` que havíamos implementado.

Sem o Scrum, essa informação teria chegado tarde — provavelmente na entrega final. A Review permitiu reordenar o backlog antes da Sprint 2: adicionamos o filtro por `municipio` como critério de aceitação de H07. Isso mudou o que eu faria na documentação dos casos de teste — incluí o cenário de filtro por `municipio` nos 20 casos da Fase 2, o que não estaria lá se o feedback não tivesse chegado via Review.

---

## 3. Uma dificuldade e o que aprendi

**Dificuldade:** Elaborar os casos de teste sem nunca ter usado Django nem a API diretamente foi difícil. Eu dependia de Igor e Icaro para confirmar o comportamento real de cada endpoint antes de documentar o "resultado esperado". Nas primeiras versões, escrevi casos de teste com status codes errados (ex.: esperava 200 para DELETE, mas a API retorna 204).

**O que aprendi:** Documentar testes sem executá-los gera erros. A solução foi criar uma sessão de pair review: Icaro rodava o Postman enquanto eu escrevia o caso de teste simultaneamente, com ele avisando quando o resultado esperado estava errado. Funcionou como programação em pares aplicada à documentação — piloto (Icaro com o Postman) e navegador (eu com o documento). Aprendi que a documentação de testes é mais confiável quando quem documenta e quem executa trabalham juntos, mesmo que informalmente.
