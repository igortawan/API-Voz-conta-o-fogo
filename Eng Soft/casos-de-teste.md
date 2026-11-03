# Casos de Teste e Matriz de Rastreabilidade

**Projeto:** Voz Contra o Fogo — API REST  
**Versão:** 1.0  
**Data:** 2026-11-03  
**Total de casos:** 20

---

## Legenda de Técnicas

- **PE** — Partição de Equivalência
- **VL** — Análise do Valor Limite
- **TD** — Tabela de Decisão

---

## Módulo: Autenticação (RF-01 a RF-03)

| ID    | Título                                      | Técnica | Pré-condição                     | Passos                                                                                     | Resultado Esperado                                           | Automação | Teste #  |
|-------|---------------------------------------------|---------|----------------------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------------------|-----------|----------|
| CT-01 | Registro com dados válidos                  | PE      | Nenhum usuário com o e-mail      | POST /api/v1/accounts/register/ com email, nome, password, role válidos                    | HTTP 201 + campos access e refresh no body                   | Sim       | Teste 1  |
| CT-02 | Registro com e-mail duplicado               | PE      | Usuário com e-mail já cadastrado | POST /api/v1/accounts/register/ com mesmo e-mail                                           | HTTP 409 com code='email_conflict'                           | Sim       | Teste 2  |
| CT-03 | Registro sem campo obrigatório (password)   | VL      | Nenhum                           | POST /api/v1/accounts/register/ omitindo password                                          | HTTP 400 com detalhes do campo ausente                       | Não       | —        |
| CT-04 | Login com credenciais válidas               | PE      | Usuário cadastrado                | POST /api/v1/accounts/login/ com email e password corretos                                 | HTTP 200 + tokens access e refresh                           | Sim       | Teste 3  |
| CT-05 | Login com senha errada                      | PE      | Usuário cadastrado                | POST /api/v1/accounts/login/ com password incorreta                                        | HTTP 401 com mensagem de erro                                | Não       | —        |
| CT-06 | Acesso a endpoint protegido sem token       | TD      | Nenhum                           | GET /api/v1/ocorrencias/ sem header Authorization                                          | HTTP 401 com code='unauthorized'                             | Sim       | Teste 4  |
| CT-07 | Consulta do perfil autenticado              | PE      | Usuário logado com token válido  | GET /api/v1/accounts/me/ com token no header                                               | HTTP 200 com email do usuário autenticado                    | Sim       | Teste 5  |

---

## Módulo: Ocorrências (RF-04 a RF-08)

| ID    | Título                                               | Técnica | Pré-condição                            | Passos                                                                                                      | Resultado Esperado                                                             | Automação | Teste # |
|-------|------------------------------------------------------|---------|-----------------------------------------|-------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|-----------|---------|
| CT-08 | Criar ocorrência com payload completo                | PE      | Usuário cidadão autenticado             | POST /api/v1/ocorrencias/ com todos os campos (OCORRENCIA_BASE)                                             | HTTP 201 com id e score_prioridade                                             | Sim       | Teste 6 |
| CT-09 | Criar ocorrência sem nivel_fogo (campo obrigatório)  | PE      | Usuário cidadão autenticado             | POST /api/v1/ocorrencias/ omitindo nivel_fogo                                                               | HTTP 400 com code='bad_request' e nivel_fogo em details                        | Sim       | Teste 14|
| CT-10 | Listar ocorrências com paginação                    | PE      | Cidadão autenticado, ≥1 ocorrência no banco | GET /api/v1/ocorrencias/                                                                                | HTTP 200 com chave results e header Cache-Control                              | Sim       | Teste 7 |
| CT-11 | Filtrar ocorrências por status=pendente              | PE      | Ocorrências com status diferentes no banco | GET /api/v1/ocorrencias/?status=pendente                                                                | HTTP 200; todos os itens com status='pendente'                                 | Sim       | Teste 12|
| CT-12 | Ordenar por score_prioridade decrescente             | VL      | Ocorrências com scores diferentes (10 e 95) | GET /api/v1/ocorrencias/?ordering=-score_prioridade                                                    | HTTP 200; item[0].score >= item[1].score                                       | Sim       | Teste 15|
| CT-13 | Consultar ocorrência inexistente                     | VL      | UUID aleatório não cadastrado            | GET /api/v1/ocorrencias/{uuid_aleatorio}/                                                                   | HTTP 404 com code='not_found'                                                  | Sim       | Teste 13|
| CT-14 | Consultar score de ocorrência                        | PE      | Ocorrência com score_prioridade=90       | GET /api/v1/ocorrencias/{id}/score/                                                                         | HTTP 200 com campos score e recomendacao                                       | Sim       | Teste 11|

---

## Módulo: Controle de Acesso (RF-09 — Segurança)

| ID    | Título                                                 | Técnica | Pré-condição                                    | Passos                                                                                 | Resultado Esperado                     | Automação | Teste # |
|-------|--------------------------------------------------------|---------|-------------------------------------------------|----------------------------------------------------------------------------------------|----------------------------------------|-----------|---------|
| CT-15 | Autoridade atualiza status de ocorrência               | TD      | Ocorrência pendente, usuário role='autoridade'  | PATCH /api/v1/ocorrencias/{id}/ com status='em_analise'                                | HTTP 200; status atualizado no banco   | Sim       | Teste 8 |
| CT-16 | Cidadão tenta atualizar status (proibido)              | TD      | Ocorrência pendente, usuário role='cidadao'     | PATCH /api/v1/ocorrencias/{id}/ com status='atendida'                                  | HTTP 403 Forbidden                     | Sim       | Teste 9 |
| CT-17 | Autoridade deleta ocorrência                           | TD      | Ocorrência existente, usuário role='autoridade' | DELETE /api/v1/ocorrencias/{id}/                                                        | HTTP 204 No Content; ocorrência removida | Sim     | Teste 10|
| CT-18 | Cidadão tenta deletar ocorrência de outro cidadão      | TD      | Ocorrência de outro usuário                     | DELETE /api/v1/ocorrencias/{id}/ autenticado como cidadão diferente                    | HTTP 403 ou HTTP 404                   | Não       | —       |

---

## Módulo: Valor Limite (latitude/longitude)

| ID    | Título                                          | Técnica | Pré-condição            | Passos                                                              | Resultado Esperado                         | Automação | Teste # |
|-------|-------------------------------------------------|---------|-------------------------|---------------------------------------------------------------------|--------------------------------------------|-----------|---------|
| CT-19 | Latitude no limite válido (-90.0)               | VL      | Cidadão autenticado     | POST /api/v1/ocorrencias/ com latitude='-90.0'                      | HTTP 201 (valor limite aceito)             | Não       | —       |
| CT-20 | Latitude fora do limite válido (-91.0)          | VL      | Cidadão autenticado     | POST /api/v1/ocorrencias/ com latitude='-91.0'                      | HTTP 400 (valor inválido rejeitado)        | Não       | —       |

---

## Tabela de Decisão — Controle de Acesso (RF-09)

| Condição                     | CT-15 | CT-16 | CT-17 | CT-18 |
|------------------------------|-------|-------|-------|-------|
| Usuário autenticado           | Sim   | Sim   | Sim   | Sim   |
| Role = autoridade             | Sim   | Não   | Sim   | Não   |
| Ocorrência existe             | Sim   | Sim   | Sim   | Sim   |
| **Resultado esperado**        | **200** | **403** | **204** | **403/404** |

---

## Matriz de Rastreabilidade

| Requisito | Descrição resumida                                 | Casos de Teste Associados               | Teste Automatizado      | Status    |
|-----------|----------------------------------------------------|-----------------------------------------|-------------------------|-----------|
| RF-01     | Registro de novo usuário                           | CT-01, CT-02, CT-03                     | CT-01 (T1), CT-02 (T2)  | Coberto   |
| RF-02     | Autenticação por e-mail e senha (JWT)              | CT-04, CT-05, CT-06                     | CT-04 (T3), CT-06 (T4)  | Coberto   |
| RF-03     | Consulta do perfil autenticado                     | CT-07                                   | CT-07 (T5)              | Coberto   |
| RF-04     | Criação de ocorrência de incêndio                  | CT-08, CT-09                            | CT-08 (T6), CT-09 (T14) | Coberto   |
| RF-05     | Listagem de ocorrências com paginação              | CT-10                                   | CT-10 (T7)              | Coberto   |
| RF-06     | Filtragem por status e ordenação por score         | CT-11, CT-12                            | CT-11 (T12), CT-12 (T15)| Coberto   |
| RF-07     | Consulta de score de prioridade por ID             | CT-14                                   | CT-14 (T11)             | Coberto   |
| RF-08     | Identificação de ocorrência inexistente            | CT-13                                   | CT-13 (T13)             | Coberto   |
| RF-09     | Controle de acesso por role (cidadão × autoridade) | CT-15, CT-16, CT-17, CT-18              | CT-15 (T8), CT-16 (T9), CT-17 (T10) | Coberto |
| RNF-01    | Segurança: endpoints protegidos por JWT            | CT-06                                   | CT-06 (T4)              | Coberto   |
| RNF-02    | Validação de dados de entrada                      | CT-03, CT-05, CT-09, CT-20              | CT-09 (T14)             | Parcial   |
| RNF-03    | Limite de coordenadas geográficas                  | CT-19, CT-20                            | —                       | Manual    |
