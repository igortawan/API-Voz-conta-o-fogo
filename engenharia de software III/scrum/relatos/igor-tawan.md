# Relato Individual — Igor Tawan

**Papel:** Product Owner (Sprint 1 e Sprint 2) · Scrum Master (Sprint 2) · Desenvolvedor  
**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas

---

## 1. Três contribuições com evidência

### Contribuição 1 — Versionamento URI e Cache-Control

Implementei o versionamento de todas as rotas da API para `/api/v1/` e adicionei o header `Cache-Control` no endpoint de listagem de ocorrências, conforme exige o Requisito 2 (princípios REST) da atividade.

**Evidência no commit:**  
[`d86b3de`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/d86b3de) — `feat: adiciona versionamento URI /api/v1/ em todas as rotas`  
[`df53a9c`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/df53a9c) — `feat: adiciona header Cache-Control em GET /ocorrencias/`

---

### Contribuição 2 — Pipeline CI/CD e elevação para 15 testes

Configurei o GitHub Actions (`.github/workflows/tests.yml`) com PostgreSQL como service container, integração de cobertura via `coverage.py` com barreira mínima de 70%, e ampliei a suíte de 13 para 15 testes, garantindo os testes de TDD (Testes 14 e 15) com ciclo Red-Green-Refactor documentado.

**Evidência no commit:**  
[`b4cdd48`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/b4cdd48) — `test(ci): adicionar pipeline GitHub Actions e elevar suite para 15 testes`

---

### Contribuição 3 — Score de prioridade automático (funcionalidade inovadora)

Implementei o cálculo automático de score de prioridade com base em `nivel_fogo`, `ha_fumaca` e `proximo_residencia`, persistido em banco e exposto via `GET /api/v1/ocorrencias/{id}/score/`. Também habilitei a ordenação por score no ViewSet.

**Evidência no commit:**  
[`c2c965d`](https://github.com/igortawan/API-Voz-conta-o-fogo/commit/c2c965d) — `Habilita ordenacao por score e data nas ocorrencias`

---

## 2. Uma decisão em que o Scrum mudou o que eu faria

Na **Retrospectiva da Sprint 1**, a equipe identificou que estava corrigindo bugs de regressão ao final de cada história — o que custava tempo não planejado. A solução apontada no "Começar a fazer" foi adotar TDD a partir da Sprint 2.

Sem o Scrum, eu teria continuado escrevendo testes depois do código (como fiz nas primeiras histórias). A cerimônia de retrospectiva formalizou a mudança: o TDD entrou no DoD e nos critérios das histórias H08 e H05 na Sprint 2. O resultado foi zero regressões no sprint 2 — confirmado pela CI rodando todos os 15 testes sem falha em nenhum push.

---

## 3. Uma dificuldade e o que aprendi

**Dificuldade:** Configurar o serviço PostgreSQL no GitHub Actions foi mais complexo do que esperava. O pipeline falhava silenciosamente porque o banco subia depois da aplicação tentar conectar — sem mensagem de erro clara. Levei quase um dia para descobrir que era necessário adicionar `options: --health-cmd pg_isready` no service container para garantir que o banco estivesse pronto antes do `python manage.py migrate`.

**O que aprendi:** Variáveis de ambiente e ordering de serviços em CI/CD são críticos e não óbvios. A documentação do GitHub Actions para services é incompleta para o caso do PostgreSQL com Django — precisei combinar 3 fontes diferentes para resolver. Isso me ensinou a sempre testar o pipeline localmente com `act` (Docker local) antes de fazer push, economizando tempo de feedback loop.
