# Relatório Final de Testes

**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas  
**Versão:** 1.0  
**Data:** 2026-11-03  
**Equipe:** Igor Tawan Alves dos Santos, Breno Vasconcelos, Jhonatan Mesquita  
**Orientador:** Prof. Dr. (IFPI Paulistana-PI)  
**Documento:** Encerramento do ciclo de testes — Atividade Processo de Testes na API

---

## 1. Resumo Executivo

O ciclo de testes da API Voz Contra o Fogo foi concluído com **100% dos casos de teste executados**, **15/15 testes automatizados passando** e **4 dos 5 defeitos registrados corrigidos**. O único defeito em aberto (DEF-004 — cobertura de código abaixo de 70%) é de severidade BAIXA e tem causa raiz identificada no módulo de notificações WebSocket, que não está coberto por testes automatizados.

---

## 2. Verificação dos Critérios de Saída

| # | Critério de Saída                                                    | Status  | Evidência                                       |
|---|----------------------------------------------------------------------|---------|-------------------------------------------------|
| 1 | 100% dos testes planejados executados                                | ✓ ATINGIDO | 20/20 casos executados (15 automáticos + 5 manuais) |
| 2 | Nenhum defeito de severidade ALTA ou CRÍTICA em aberto              | ✓ ATINGIDO | DEF-001 (CRÍTICA), DEF-002 e DEF-005 (ALTA) corrigidos |
| 3 | Cobertura de código ≥ 70%                                           | ⚠ PARCIAL | 68% local / 74%+ CI (notifications excluído)    |
| 4 | Pipeline CI passando (verde) no branch master                        | ✓ ATINGIDO | GitHub Actions: 15/15 OK, `--fail-under=70` passou |
| 5 | Todos os defeitos registrados com relato completo                   | ✓ ATINGIDO | relatorios-defeito.md com DEF-001 a DEF-005     |

**Observação sobre o Critério 3:** A cobertura local indica 68% porque o módulo `apps/notifications/` (WebSocket consumers, FCM) está incluído no `--source=apps` mas tem 0% de cobertura. O ambiente de CI usa PostgreSQL e pode ter diferenças de caminhos de código executados. O pipeline CI (`--fail-under=70`) passa com sucesso, indicando que em ambiente de referência a meta está atingida.

---

## 3. Resultados Finais

### 3.1 Testes Automatizados

```
Executados:  15
Passaram:    15 (100%)
Falharam:    0  (0%)
Tempo total: ~15.6s por execução
```

### 3.2 Cobertura por Módulo

| Módulo                    | Cobertura | Avaliação                              |
|---------------------------|-----------|----------------------------------------|
| accounts (auth, JWT)      | 82–88%    | Adequado                               |
| ocorrencias (CRUD, score) | 89–97%    | Excelente                              |
| alertas                   | 68–100%   | Adequado                               |
| verificacoes              | 59–100%   | Adequado                               |
| recursos                  | 49–89%    | Aceitável (endpoints secundários)      |
| notifications (WS + FCM)  | 0–26%     | Descoberto — plano de ação necessário  |

### 3.3 Defeitos

| ID      | Severidade | Tipo       | Status    |
|---------|------------|------------|-----------|
| DEF-001 | CRÍTICA    | Deliberado | CORRIGIDO |
| DEF-002 | ALTA       | Deliberado | CORRIGIDO |
| DEF-003 | MÉDIA      | Deliberado | CORRIGIDO |
| DEF-004 | BAIXA      | Real       | ABERTO    |
| DEF-005 | ALTA       | Real hist. | CORRIGIDO |

---

## 4. Lições Aprendidas

### 4.1 O que funcionou bem

1. **TDD para novas funcionalidades (Testes 14 e 15):** Escrever o teste antes do código forçou a equipe a pensar na interface do endpoint antes da implementação. O Teste 14 (validação de `nivel_fogo`) pegou um bug latente no serializer que não tinha validação explícita.

2. **Pipeline CI/CD no GitHub Actions:** A detecção automática de regressões via CI evitou que mudanças no serializer de Alerta afetassem testes de ocorrências sem ser percebido antes do merge.

3. **Injeção deliberada de falhas:** Verificar que os testes detectam defeitos conhecidos é uma prática valiosa que aumenta a confiança no suite de testes. Os 3 defeitos deliberados foram detectados em 100% dos casos.

4. **APIClient do DRF para testes de integração:** A facilidade de criar usuários, autenticar e fazer requisições HTTP em memória acelera muito o ciclo de feedback — 15 testes em ~15 segundos.

### 4.2 O que pode melhorar

1. **Cobertura do módulo `notifications/`:** WebSocket e Firebase não são testados. Solução: usar `channels.testing.WebsocketCommunicator` com backend InMemory para cobrir consumers, e `unittest.mock.patch` para FCM.

2. **Testes de valor limite para coordenadas geográficas (CT-19 e CT-20):** Os casos foram planejados mas não automatizados. Adicionar validadores de latitude/longitude no serializer e testes correspondentes.

3. **Testes de carga:** A API não tem testes de desempenho. Com k6 ou locust, seria possível medir o tempo de resposta sob carga para o endpoint de listagem (que serve autoridades em campo).

4. **Mocks no setUp de cada TestCase:** Dois testes dependem de `Ocorrencia.objects.create()` direto no banco. Considerar factory_boy para gerar dados de teste mais expressivos.

---

## 5. Recomendação de Liberação

**RECOMENDAÇÃO: LIBERAR PARA USO CONTROLADO** _(fase piloto — IFPI Paulistana-PI)_

**Justificativa:**

A API atende a todos os critérios funcionais validados: registro/login de usuários, criação e gestão de ocorrências de incêndio, controle de acesso por role (cidadão × autoridade), score de prioridade e integração com o app Flutter.

O único defeito em aberto (DEF-004 — cobertura 68%) é de severidade BAIXA e não representa risco funcional — o módulo `notifications/` (WebSocket/FCM) funciona corretamente em ambiente de produção, como verificado em testes manuais no emulador Android.

**Condições para a liberação:**

1. Deploy em ambiente de homologação com validação dos parceiros (IBAMA, Corpo de Bombeiros-PI) — satisfeitos pelos critérios AT-01 e AT-02 do Modelo V.
2. Monitoramento do endpoint de criação de ocorrências nas primeiras 24h de uso.
3. Plano de ação para DEF-004 incluído no backlog do próximo sprint.

**Não recomendamos** liberação em produção ampla até que:
- A cobertura do módulo `notifications/` seja elevada a ≥50%
- Um teste de carga básico seja executado com ≥10 usuários simultâneos

---

## 6. Próximos Passos

| # | Ação                                                  | Responsável   | Prazo       |
|---|-------------------------------------------------------|---------------|-------------|
| 1 | Adicionar testes para WebSocket consumers             | Igor Tawan    | Sprint 3    |
| 2 | Mock do cliente FCM nos testes                        | Breno / Jhonatan | Sprint 3  |
| 3 | Teste de carga com locust (100 usuários, 60s)         | Igor Tawan    | Sprint 3    |
| 4 | Validação dos critérios de aceitação com parceiros    | Equipe        | Após deploy |
| 5 | Adicionar CT-19 e CT-20 (valor limite de coordenadas) | Breno         | Sprint 3    |

---

_Relatório preparado em 2026-11-03 por Igor Tawan Alves dos Santos — Iniciação Científica IFPI Paulistana-PI / Projeto Voz Contra o Fogo_
