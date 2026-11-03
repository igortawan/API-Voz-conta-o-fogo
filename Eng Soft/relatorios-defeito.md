# Relatórios de Defeito

**Projeto:** Voz Contra o Fogo — API REST  
**Versão da API:** 1.0  
**Data:** 2026-11-03

---

## DEF-001 — Endpoint de ocorrências sem proteção de autenticação

| Campo           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| **ID**          | DEF-001                                                               |
| **Título**      | Remoção de autenticação expõe /api/v1/ocorrencias/ a usuários não autenticados |
| **Tipo**        | Falha deliberada (injetada para verificar detecção pelos testes)      |
| **Data descoberta** | 2026-11-03                                                        |
| **Descoberto por**  | Injeção deliberada + Teste 4 (test_unauthenticated_access_returns_401) |
| **Severidade**  | CRÍTICA                                                               |
| **Prioridade**  | ALTA                                                                  |
| **Status**      | CORRIGIDO (revertido imediatamente)                                   |

**Descrição:**  
A classe `OcorrenciaListCreateView` teve sua `permission_classes` alterada de `[IsAuthenticated]` para `[AllowAny]`, removendo a barreira de autenticação JWT.

**Passos para reproduzir:**
1. Alterar `permission_classes = [permissions.AllowAny]` em `apps/ocorrencias/views.py`
2. Executar `GET /api/v1/ocorrencias/` sem header `Authorization`

**Resultado obtido:**  
HTTP 500 — `AttributeError: 'AnonymousUser' object has no attribute 'role'`

**Resultado esperado:**  
HTTP 401 com body `{"code": "unauthorized"}`

**Impacto:**  
Qualquer usuário não autenticado poderia acessar o endpoint, e o crash (500) revelaria informações do stack trace em ambiente de debug.

**Detecção:**  
Teste automatizado `test_unauthenticated_access_returns_401` detectou a falha:
```
AssertionError: 500 != 401
```

**Correção aplicada:**  
Restaurada `permission_classes = [permissions.IsAuthenticated]` em `OcorrenciaListCreateView`.

---

## DEF-002 — Escalonamento de privilégio: cidadão consegue alterar status de ocorrência

| Campo           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| **ID**          | DEF-002                                                               |
| **Título**      | Cidadão com role='cidadao' consegue fazer PATCH em /ocorrencias/{id}/ |
| **Tipo**        | Falha deliberada (injetada para verificar detecção pelos testes)      |
| **Data descoberta** | 2026-11-03                                                        |
| **Descoberto por**  | Injeção deliberada + Teste 9 (test_cidadao_cannot_update_status)  |
| **Severidade**  | ALTA                                                                  |
| **Prioridade**  | ALTA                                                                  |
| **Status**      | CORRIGIDO (revertido imediatamente)                                   |

**Descrição:**  
O método `get_permissions` da `OcorrenciaDetailView` foi alterado para retornar `[IsAuthenticated()]` para métodos PUT/PATCH/DELETE, removendo a verificação de `role='autoridade'`.

**Passos para reproduzir:**
1. Alterar `get_permissions` para retornar `[IsAuthenticated()]` em vez de `[IsAuthoridade()]`
2. Autenticar como usuário com `role='cidadao'`
3. Executar `PATCH /api/v1/ocorrencias/{id}/` com `{"status": "atendida"}`

**Resultado obtido:**  
HTTP 200 — status atualizado com sucesso por um cidadão

**Resultado esperado:**  
HTTP 403 — Forbidden

**Impacto:**  
Cidadãos poderiam encerrar ocorrências ativas, prejudicando o trabalho das autoridades de monitoramento de queimadas.

**Detecção:**  
Teste automatizado `test_cidadao_cannot_update_status` detectou:
```
AssertionError: 200 != 403
```

**Correção aplicada:**  
Restaurado `return [IsAuthoridade()]` para métodos PUT/PATCH/DELETE em `OcorrenciaDetailView.get_permissions`.

---

## DEF-003 — Criação de ocorrência retorna HTTP 200 em vez de 201

| Campo           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| **ID**          | DEF-003                                                               |
| **Título**      | POST /api/v1/ocorrencias/ retorna 200 (OK) em vez de 201 (Created)   |
| **Tipo**        | Falha deliberada (injetada para verificar detecção pelos testes)      |
| **Data descoberta** | 2026-11-03                                                        |
| **Descoberto por**  | Injeção deliberada + Teste 6 (test_create_ocorrencia_returns_201) |
| **Severidade**  | MÉDIA                                                                 |
| **Prioridade**  | MÉDIA                                                                 |
| **Status**      | CORRIGIDO (revertido imediatamente)                                   |

**Descrição:**  
Um método `create()` sobrescrito foi adicionado em `OcorrenciaListCreateView` forçando `response.status_code = 200` após a criação.

**Passos para reproduzir:**
1. Adicionar override do `create()` que force `response.status_code = 200`
2. Autenticar como cidadão
3. Executar `POST /api/v1/ocorrencias/` com payload válido

**Resultado obtido:**  
HTTP 200 — recurso criado mas com código errado

**Resultado esperado:**  
HTTP 201 — Created (padrão REST para criação bem-sucedida de recurso)

**Impacto:**  
O app Flutter (cliente) verifica o código 201 para confirmar a criação. Um 200 faria o cliente não registrar a ocorrência corretamente, potencialmente perdendo denúncias de incêndio.

**Detecção:**  
Teste automatizado `test_create_ocorrencia_returns_201` detectou:
```
AssertionError: 200 != 201
```

**Correção aplicada:**  
Removido o override do método `create()`. O `generics.ListCreateAPIView` retorna 201 por padrão.

---

## DEF-004 — Cobertura de código abaixo do limiar de 70%

| Campo           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| **ID**          | DEF-004                                                               |
| **Título**      | Cobertura de código em 68% — abaixo do mínimo de 70% exigido         |
| **Tipo**        | Defeito real (identificado durante execução de testes)                |
| **Data descoberta** | 2026-11-03                                                        |
| **Descoberto por**  | Relatório `coverage report --show-missing`                        |
| **Severidade**  | BAIXA                                                                 |
| **Prioridade**  | MÉDIA                                                                 |
| **Status**      | ABERTO                                                                |

**Descrição:**  
A cobertura total em ambiente local ficou em 68% (571 statements, 182 missed). O módulo `apps/notifications/` tem 0% de cobertura: WebSocket consumers, middleware de autenticação WebSocket e cliente FCM (Firebase Cloud Messaging) não são testados automaticamente.

**Módulos descobertos:**

| Módulo                              | Cobertura |
|-------------------------------------|-----------|
| apps/notifications/consumers.py     | 0%        |
| apps/notifications/middleware.py    | 0%        |
| apps/notifications/routing.py       | 0%        |
| apps/notifications/fcm.py           | 26%       |
| apps/ocorrencias/services.py        | 47%       |

**Causa raiz:**  
Testes de WebSocket requerem configuração adicional (ASGI, Channel Layers com backend InMemory) e são complexos de executar em ambiente de teste padrão do Django.

**Recomendação:**  
Adicionar `pytest-channels` ou mock do `get_channel_layer()` para cobrir os consumers. Mínimo aceitável: descartar `notifications/` do `--source` até os testes WebSocket serem implementados.

---

## DEF-005 — Flutter enviava status 'enviada' ao criar ocorrência (histórico)

| Campo           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| **ID**          | DEF-005                                                               |
| **Título**      | App Flutter enviava status='enviada' ao criar ocorrência — Django retornava 400 |
| **Tipo**        | Defeito real histórico                                                |
| **Data descoberta** | 2026-10-28 (sprint 1)                                             |
| **Descoberto por**  | Teste manual — criação de ocorrência no emulador Android          |
| **Severidade**  | ALTA                                                                  |
| **Prioridade**  | ALTA                                                                  |
| **Status**      | CORRIGIDO — commit `dd21ac8`                                         |

**Descrição:**  
O app Flutter enviava o campo `status: 'enviada'` no payload de criação de ocorrência. O Django rejeitava com HTTP 400 porque `'enviada'` não é um valor válido para o campo `status` (valores aceitos: `'pendente'`, `'em_analise'`, `'atendida'`, `'cancelada'`).

**Passos para reproduzir:**
1. App Flutter envia POST com `status: 'enviada'`
2. Django valida o campo via `ChoiceField`

**Resultado obtido:**  
HTTP 400 — `{"status": ["Value 'enviada' is not a valid choice."]}`

**Resultado esperado:**  
HTTP 201 com `status: 'pendente'` (valor padrão)

**Correção aplicada:**  
Removido o campo `status` do payload enviado pelo Flutter. O Django usa `status='pendente'` como valor padrão definido no modelo.

**Evidência:**  
Commit `dd21ac8 — Corrige envio de status invalido ao criar ocorrencia no Django`
