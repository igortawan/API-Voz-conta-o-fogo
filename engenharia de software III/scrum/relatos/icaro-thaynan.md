# Relato Individual — Icaro Thaynan

**Papel:** Scrum Master (Sprint 1) · Desenvolvedor  
**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas

---

## 1. Três contribuições com evidência

### Contribuição 1 — Model, serializer e endpoint de criação de ocorrência (H03)

Implementei o model `Ocorrencia` com os campos de localização GPS, nível de fogo, fumaça e status. Criei o serializer com validações iniciais e a view de criação via `POST /api/v1/ocorrencias/`, com retorno 201 e tratamento de erros 400. A funcionalidade foi a base sobre a qual o score de prioridade foi depois calculado pelo Igor.

**Evidência no commit:**  
[`069964b`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/069964b) — `Versão inicial do backend Django — API Voz Contra o Fogo`  
[`a4a5253`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/a4a5253) — `feat: adiciona DELETE em ocorrencias e 409 Conflict no registro`

---

### Contribuição 2 — Restrição de papel em PATCH de status (H07)

Implementei a regra de negócio que impede cidadãos de alterar o status de uma ocorrência (retorna 403 Forbidden) e permite somente autoridades (`is_staff=True`). Escrevi os testes de permissão e abri o PR para revisão do Igor antes do merge — primeira vez que seguimos o fluxo de PR revisado no projeto.

**Evidência no commit:**  
[`8dae35b`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/8dae35b) — `feat: adiciona handler de erros padronizados {code, message, details}`

---

### Contribuição 3 — Documentação OpenAPI com drf-spectacular (H13)

Configurei o `drf-spectacular` para gerar automaticamente a documentação OpenAPI 3.0 em `/api/v1/docs/` (Swagger UI) e `/api/v1/schema/`. Atualizei o README com instruções de acesso e revisei o PR de testes do Igor para garantir que o schema não quebrava nenhum contrato existente.

**Evidência no commit:**  
[`ae19ba5`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/ae19ba5) — `feat: adiciona documentação OpenAPI via drf-spectacular`

---

## 2. Uma decisão em que o Scrum mudou o que eu faria

No **Sprint Planning da Sprint 1**, eu queria já implementar a detecção de duplicatas (H06) junto com a criação de ocorrência (H03), pois parecia uma funcionalidade relacionada. O Sprint Planning deixou claro que H06 tinha estimativa de 5 pontos e não cabia na capacidade da Sprint 1 (15 pontos com 3 histórias já previstas). A priorização MoSCoW marcou H06 como "Should Have" — sem urgência.

Isso foi importante: eu teria gastado tempo em H06 e arriscado não terminar H03 com qualidade. A separação por sprint forçou foco, e H03 saiu com testes adequados e PR revisado — o que não teria acontecido se eu estivesse dividido entre as duas histórias ao mesmo tempo.

---

## 3. Uma dificuldade e o que aprendi

**Dificuldade:** Entender o sistema de permissões do Django REST Framework para H07 foi desafiador. O DRF tem três camadas de permissão (globais, por view e por objeto), e minha primeira implementação usava a camada errada — a restrição não funcionava para o endpoint de `partial_update`. Abri a questão na Daily de 31/10 e o Igor explicou a diferença entre `permission_classes` e `get_object()` com `check_object_permissions()`.

**O que aprendi:** Problemas travados devem aparecer na Daily sem hesitar — o impedimento foi registrado, o Scrum Master (eu mesmo, nesta sprint) coordenou a solução em menos de 2 horas. O Scrum não resolve o problema técnico, mas garante que ele não fica escondido por dias. Aprendi também que a documentação do DRF sobre permissões por objeto é mais clara nos exemplos de código do que no texto — leitura de código > leitura de doc neste caso.
