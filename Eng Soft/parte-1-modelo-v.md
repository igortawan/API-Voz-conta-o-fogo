# Parte 1 — Modelo V de Testes

**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas  
**Disciplina:** Engenharia de Software  
**Equipe:** Igor Tawan, Breno Vasconcelos, Jhonatan Mesquita

---

## 1. Diagrama em V — Artefatos Reais do Projeto

```
DESENVOLVIMENTO                          TESTES
─────────────────────────────────────────────────────────────────────────

Requisitos de negócio              ←──────────────→  Testes de aceitação
(Proposta FAPEPI, objetivos IC)                       (AT-01, AT-02)
Instituição: IFPI Paulistana-PI
         │                                                  ↑
         ▼                                                  │
Especificação do sistema           ←──────────────→  Testes de sistema
(OpenAPI / drf-spectacular)                           (ST-01, ST-02)
Arquivo: docs/ (gerado p/ /api/schema/)
         │                                                  ↑
         ▼                                                  │
Projeto de arquitetura             ←──────────────→  Testes de integração
(camadas DRF, banco PostgreSQL,                       (IT-01, IT-02)
 WebSocket/Channels, JWT)
         │                                                  ↑
         ▼                                                  │
Projeto detalhado e código         ←──────────────→  Testes de unidade
(ViewSets, serializers,                               (UT-01, UT-02)
 score_prioridade, detectar_duplicata)
         │
         ▼
    IMPLEMENTAÇÃO
    (código Django + Flutter)
```

---

## 2. Casos de Teste por Nível (2 por nível)

### 2.1 Testes de Unidade

| ID    | Nome                                | Entrada                                                            | Resultado Esperado                        | Tipo          |
|-------|-------------------------------------|--------------------------------------------------------------------|-------------------------------------------|---------------|
| UT-01 | Cálculo de score_prioridade crítico | nivel_fogo='critico', ha_fumaca=True, proximo_residencia=True      | score >= 90                               | Verificação   |
| UT-02 | Validação de nivel_fogo obrigatório | POST em /api/v1/ocorrencias/ sem campo nivel_fogo                  | 400 Bad Request com code='bad_request'    | Verificação   |

**Mapeamento no código:**
- UT-01 → lógica em `apps/ocorrencias/utils.py` (função `calcular_score`)
- UT-02 → `tests/test_api.py` — Teste 14 (`test_create_ocorrencia_missing_nivel_fogo_returns_400`)

---

### 2.2 Testes de Integração

| ID    | Nome                                     | Entrada                                                                  | Resultado Esperado                                        | Tipo          |
|-------|------------------------------------------|--------------------------------------------------------------------------|-----------------------------------------------------------|---------------|
| IT-01 | Criar ocorrência persiste no banco       | POST autenticado com payload completo (OCORRENCIA_BASE)                   | HTTP 201 + registro salvo no banco + score_prioridade > 0 | Verificação   |
| IT-02 | Autoridade atualiza status no banco      | PATCH /ocorrencias/{id}/ por usuário role='autoridade', status='em_analise' | HTTP 200 + oc.status == 'em_analise' no banco           | Verificação   |

**Mapeamento:**
- IT-01 → `tests/test_api.py` — Teste 6 (`test_create_ocorrencia_returns_201`)
- IT-02 → `tests/test_api.py` — Teste 8 (`test_autoridade_can_update_status`)

---

### 2.3 Testes de Sistema

| ID    | Nome                                       | Entrada                                    | Resultado Esperado                                           | Tipo          |
|-------|--------------------------------------------|--------------------------------------------|--------------------------------------------------------------|---------------|
| ST-01 | Acesso sem token retorna 401               | GET /api/v1/ocorrencias/ sem Authorization | HTTP 401, body com code='unauthorized'                       | Verificação   |
| ST-02 | Fluxo completo: registro → login → denúncia | Sequência: POST /register → POST /login → POST /ocorrencias/ | Cada passo retorna código esperado; ocorrência criada com ID  | Validação     |

**Mapeamento:**
- ST-01 → `tests/test_api.py` — Teste 4 (`test_unauthenticated_access_returns_401`)
- ST-02 → exercido por Testes 1, 3 e 6 em sequência

---

### 2.4 Testes de Aceitação

| ID    | Nome                                             | Critério (Dado / Quando / Então)                                                                                                              | Tipo       |
|-------|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|------------|
| AT-01 | Cidadão denuncia incêndio pelo app Flutter       | **Dado** que o cidadão está autenticado e com GPS ativo **Quando** preenche o formulário de ocorrência e envia **Então** recebe confirmação com ID único e score de prioridade | Validação  |
| AT-02 | Autoridade prioriza atendimento pelo painel      | **Dado** que a autoridade acessa o app **Quando** visualiza a lista de ocorrências **Então** vê ordenação por score_prioridade (maior primeiro) e pode atualizar o status | Validação  |

**Evidência de aceitação:** executados manualmente durante a sprint de entrega; comportamento confirmado no emulador Android (AVD Medium Phone API 36).

---

## 3. Classificação: Verificação × Validação

| ID    | Classificação | Justificativa                                                                              |
|-------|---------------|-------------------------------------------------------------------------------------------|
| UT-01 | Verificação   | Confirma que o código calcula o score conforme especificação interna (regra definida pela equipe) |
| UT-02 | Verificação   | Confirma conformidade com a especificação do serializer (campo obrigatório pelo schema OpenAPI) |
| IT-01 | Verificação   | Verifica que os componentes (View, Serializer, Model) interagem corretamente entre si      |
| IT-02 | Verificação   | Confirma que a camada de negócio respeita restrição de permissão (role-based access)       |
| ST-01 | Verificação   | Confirma comportamento do sistema conforme requisito de segurança especificado              |
| ST-02 | Validação     | Avalia se o fluxo completo satisfaz a necessidade real do usuário final                   |
| AT-01 | Validação     | Verifica se o produto atende ao objetivo de negócio declarado na proposta FAPEPI           |
| AT-02 | Validação     | Confirma com o orientador/parceiro se a funcionalidade é útil no contexto de brigadas de incêndio |

**Distinção adotada:**
- **Verificação** — *"Estamos construindo o produto corretamente?"* (conformidade com especificações internas)
- **Validação** — *"Estamos construindo o produto certo?"* (atendimento às necessidades reais dos stakeholders)

---

## 4. Reflexão sobre o Modelo V (≥ 10 linhas)

O Modelo V foi criado como evolução do modelo cascata para tornar explícita a relação entre cada fase de desenvolvimento e seu nível de teste correspondente. Aplicá-lo ao projeto Voz Contra o Fogo revelou benefícios e limitações práticas.

O principal benefício observado foi a **rastreabilidade bidirecional**: cada artefato de teste remete diretamente a um artefato de desenvolvimento, facilitando identificar qual requisito está coberto e qual está descoberto. No nosso caso, os 15 testes automatizados mapeiam com clareza os endpoints documentados na especificação OpenAPI.

Por outro lado, o modelo pressupõe que os requisitos estarão completos antes de qualquer código ser escrito — premissa difícil de sustentar num projeto acadêmico de IC onde o escopo evolui a cada reunião com os parceiros (IBAMA, Corpo de Bombeiros-PI). Na prática, os requisitos para detecção de duplicatas e o score de prioridade surgiram após o início da implementação, o que exigiu retroalimentação horizontal no diagrama.

Outro ponto relevante é que o Modelo V não aborda explicitamente testes não funcionais (desempenho, segurança, usabilidade). No projeto, o requisito de resposta < 200 ms sob carga e a segurança via JWT precisaram ser tratados fora da estrutura formal do V.

Por fim, o modelo favorece **planejamento antecipado** de critérios de aceitação, o que melhorou significativamente a comunicação com o orientador: ao apresentar os casos de aceitação AT-01 e AT-02 antes de codificar, a equipe alinhou expectativas e evitou retrabalho. Essa prática de "acceptance-first" aproxima o Modelo V do BDD (Behavior-Driven Development) e é a maior lição extraída desta etapa.
