# Log de Execução dos Testes

**Projeto:** Voz Contra o Fogo — API REST  
**Ciclo:** 1 (execução inicial) e 2 (regressão pós-correção)  
**Data:** 2026-11-03  
**Executor:** Igor Tawan  
**Ambiente:** Windows 11 / Python 3.10 / SQLite (memorydb)  
**Comando:** `python manage.py test tests --verbosity=2`

---

## Ciclo 1 — Execução Inicial (2026-11-01)

### Configuração

```
Banco de dados: SQLite in-memory (file:memorydb_default?mode=memory&cache=shared)
15 testes localizados
Migrações aplicadas: 42 OK
System check: 0 issues
```

### Resultados por Caso de Teste

| CT    | Nome do Teste Automatizado                          | Resultado | Duração  | Observação                    |
|-------|------------------------------------------------------|-----------|----------|-------------------------------|
| CT-07 | test_me_returns_user_data                            | PASS      | —        | —                             |
| CT-04 | test_login_returns_200_with_tokens                   | PASS      | —        | —                             |
| CT-02 | test_register_duplicate_email_returns_409            | PASS      | —        | —                             |
| CT-01 | test_register_returns_201_with_tokens                | PASS      | —        | —                             |
| CT-06 | test_unauthenticated_access_returns_401              | PASS      | —        | —                             |
| CT-17 | test_autoridade_can_delete_ocorrencia                | PASS      | —        | —                             |
| CT-15 | test_autoridade_can_update_status                    | PASS      | —        | —                             |
| CT-16 | test_cidadao_cannot_update_status                    | PASS      | —        | —                             |
| CT-09 | test_create_ocorrencia_missing_nivel_fogo_returns_400 | PASS     | —        | Validação TDD confirmada      |
| CT-08 | test_create_ocorrencia_returns_201                   | PASS      | —        | —                             |
| CT-11 | test_filter_by_status                                | PASS      | —        | —                             |
| CT-10 | test_list_ocorrencias_returns_200_with_pagination    | PASS      | —        | Cache-Control verificado      |
| CT-13 | test_ocorrencia_not_found_returns_404                | PASS      | —        | —                             |
| CT-12 | test_ordering_by_score_prioridade                    | PASS      | —        | Ordenação TDD confirmada      |
| CT-14 | test_score_endpoint_returns_score                    | PASS      | —        | —                             |

**Resultado:** Ran 15 tests in 15.601s — **OK**

### Cobertura de Código

```
Comando: coverage run --source=apps manage.py test tests
         coverage report --show-missing

TOTAL: 571 statements, 182 missed → 68% coverage
```

| Módulo                              | Cobertura | Linhas descobertas                  |
|-------------------------------------|-----------|-------------------------------------|
| apps/ocorrencias/views.py           | 89%       | 30, 86, 111-112, 126-129            |
| apps/ocorrencias/services.py        | 47%       | 24, 30, 38-42, 46-50, 55-70         |
| apps/notifications/consumers.py     | 0%        | 1-54 (WebSocket — fora do escopo)   |
| apps/notifications/middleware.py    | 0%        | 1-27 (WebSocket — fora do escopo)   |
| apps/notifications/fcm.py           | 26%       | Firebase push (mock não testado)    |
| apps/accounts/views.py              | 59%       | 42, 52, 60-76, 84-92, 101-105       |

**Observação:** Cobertura abaixo do limiar de 70% definido no plano. O módulo `notifications` (WebSocket + FCM) não é testado automaticamente, o que puxa a cobertura global para 68%. Registrado como DEF-004.

---

## Testes de Falhas Deliberadas (Injeção de Defeitos)

Conforme orientação da atividade, foram injetadas 3 falhas no código para verificar que os testes as detectam. Após cada teste, o código foi revertido imediatamente.

### Falha Deliberada 1 — DEF-001: Remoção da autenticação obrigatória

**Modificação aplicada em** `apps/ocorrencias/views.py` (linha 21):
```python
# ANTES (correto):
permission_classes = [permissions.IsAuthenticated]
# DEPOIS (com falha deliberada):
permission_classes = [permissions.AllowAny]
```

**Execução:**
```
python manage.py test tests.test_api.AuthTests.test_unauthenticated_access_returns_401 --verbosity=2
```

**Resultado:**
```
test_unauthenticated_access_returns_401 (tests.test_api.AuthTests) ... FAIL
FAIL: test_unauthenticated_access_returns_401
AssertionError: 500 != 401
Ran 1 test in 0.239s — FAILED (failures=1)
```

**Conclusão:** Teste detectou a falha. Sem autenticação, a view crashou (AnonymousUser não tem `.role`), gerando 500. O teste esperava 401. **Defeito detectado.**

---

### Falha Deliberada 2 — DEF-002: Cidadão com permissão de autoridade (escalonamento de privilégio)

**Modificação aplicada em** `apps/ocorrencias/views.py` (linha 79):
```python
# ANTES (correto):
if self.request.method in ['PUT', 'PATCH', 'DELETE']:
    return [IsAuthoridade()]
# DEPOIS (com falha deliberada):
if self.request.method in ['PUT', 'PATCH', 'DELETE']:
    return [permissions.IsAuthenticated()]  # qualquer usuário pode atualizar
```

**Execução:**
```
python manage.py test tests.test_api.OcorrenciaTests.test_cidadao_cannot_update_status --verbosity=2
```

**Resultado:**
```
test_cidadao_cannot_update_status (tests.test_api.OcorrenciaTests) ... FAIL
FAIL: test_cidadao_cannot_update_status
AssertionError: 200 != 403
Ran 1 test in 1.415s — FAILED (failures=1)
```

**Conclusão:** Teste detectou o escalonamento de privilégio. Cidadão conseguiu atualizar status (200) quando deveria receber 403. **Defeito detectado.**

---

### Falha Deliberada 3 — DEF-003: Criação de ocorrência retorna código HTTP errado

**Modificação aplicada em** `apps/ocorrencias/views.py`:
```python
# Código injetado (com falha deliberada):
def create(self, request, *args, **kwargs):
    response = super().create(request, *args, **kwargs)
    response.status_code = 200  # deveria ser 201
    return response
```

**Execução:**
```
python manage.py test tests.test_api.OcorrenciaTests.test_create_ocorrencia_returns_201 --verbosity=2
```

**Resultado:**
```
test_create_ocorrencia_returns_201 (tests.test_api.OcorrenciaTests) ... FAIL
FAIL: test_create_ocorrencia_returns_201
AssertionError: 200 != 201
Ran 1 test in 1.429s — FAILED (failures=1)
```

**Conclusão:** Teste detectou o código HTTP incorreto. **Defeito detectado.**

---

## Ciclo 2 — Regressão Pós-Correção (2026-11-02)

Após as correções dos defeitos DEF-001, DEF-002 e DEF-003 (que eram injetados, revertidos imediatamente), todos os 15 testes foram executados novamente.

**Resultado:**
```
Ran 15 tests in 15.825s — OK
```

Nenhuma regressão identificada. O pipeline de CI/CD (GitHub Actions) também retornou **verde** no branch master.

---

## Resumo de Execução

| Ciclo   | Testes executados | Passou | Falhou | Cobertura |
|---------|-------------------|--------|--------|-----------|
| Ciclo 1 | 15                | 15     | 0      | 68%       |
| Falhas deliberadas | 3       | 0      | 3      | —         |
| Ciclo 2 | 15                | 15     | 0      | 68%       |
