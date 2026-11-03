# Plano de Testes — Voz Contra o Fogo API

**Versão:** 1.0  
**Data:** 2026-11-03  
**Projeto:** Voz Contra o Fogo — Sistema de monitoramento de queimadas no semiárido piauiense  
**Repositório:** semiaridofogo-django  
**Responsável:** Igor Tawan  
**Orientador:** Prof. Dr. (IFPI Paulistana-PI)

---

## 1. Escopo

### 1.1 O que será testado

- API REST desenvolvida em Django REST Framework (DRF)
- Módulo de autenticação (`apps/accounts`): registro, login, perfil
- Módulo de ocorrências (`apps/ocorrencias`): CRUD, score de prioridade, filtros, ordenação, detecção de duplicatas
- Módulo de alertas (`apps/alertas`): criação e listagem
- Segurança: autenticação JWT, controle de acesso por role (cidadão × autoridade)
- Pipeline de integração contínua (GitHub Actions)

### 1.2 O que NÃO será testado

- App Flutter (cliente móvel) — fora do escopo desta atividade
- Infraestrutura de produção (deploy, DNS, SSL)
- WebSocket em tempo real (cobertura parcial — testado manualmente)
- Performance sob carga extrema (>1000 usuários simultâneos)

---

## 2. Objetivos

1. Verificar que todos os endpoints da API respondem com os códigos HTTP corretos
2. Validar que as regras de negócio (score, permissões por role, filtros) estão implementadas corretamente
3. Detectar falhas de segurança básica (acesso sem token, escalonamento de privilégios)
4. Manter cobertura de código ≥ 70% mensurada pelo `coverage.py`
5. Garantir que regressões sejam detectadas automaticamente via CI antes do merge

---

## 3. Níveis de Teste e Estratégia

| Nível          | Abordagem                                        | Ferramenta              | Responsável       |
|----------------|--------------------------------------------------|-------------------------|-------------------|
| Unidade        | Testes isolados de serializers e regras de negócio | Django TestCase + APIClient | Desenvolvedor    |
| Integração     | Testes end-to-end contra banco de dados SQLite de teste | Django TestCase + APIClient | Desenvolvedor    |
| Sistema        | Fluxos completos (registro → login → operação)   | Django TestCase          | Desenvolvedor     |
| Aceitação      | Validação com orientador e parceiros             | Manual (emulador Android) | Equipe + Orientador |
| Não funcional  | Segurança: acesso sem token, sem permissão        | Django TestCase          | Desenvolvedor     |

### 3.1 Técnicas de Projeto de Teste

- **Partição de equivalência:** agrupa entradas válidas e inválidas em classes (ex: nivel_fogo pode ser 'baixo'/'medio'/'alto'/'critico' [válidos] ou qualquer outro valor [inválido])
- **Análise do valor limite:** testa os limites dos campos (ex: latitude próxima de -90/-90, score = 0 e score = 100)
- **Tabela de decisão:** cobre combinações de role × operação × ownership para verificar controle de acesso

---

## 4. Ambiente de Teste

### 4.1 Ambiente de CI (GitHub Actions)

| Componente      | Versão / Configuração                          |
|-----------------|------------------------------------------------|
| Sistema operacional | Ubuntu Latest                              |
| Python          | 3.11                                           |
| Django          | 5.1.x                                          |
| DRF             | 3.15.x                                         |
| Banco de dados  | PostgreSQL 15 (service container)              |
| Variáveis de ambiente | SECRET_KEY, DATABASE_URL, DEBUG, ALLOWED_HOSTS |

### 4.2 Ambiente Local (desenvolvimento)

| Componente      | Versão / Configuração                          |
|-----------------|------------------------------------------------|
| Sistema operacional | Windows 11 Pro                             |
| Python          | 3.10.x                                         |
| Banco de dados  | PostgreSQL local (port 5432)                   |

---

## 5. Critérios de Entrada

| # | Critério                                                         |
|---|------------------------------------------------------------------|
| 1 | Código-fonte disponível no repositório GitHub                    |
| 2 | Dependências instaladas (`pip install -r requirements.txt`)      |
| 3 | Migrações aplicadas (`python manage.py migrate`)                 |
| 4 | Variáveis de ambiente configuradas (SECRET_KEY, DATABASE_URL)    |
| 5 | Pipeline CI configurado e funcional                              |

---

## 6. Critérios de Saída

| # | Critério                                                         |
|---|------------------------------------------------------------------|
| 1 | 100% dos testes planejados executados                            |
| 2 | Nenhum defeito de severidade ALTA ou CRÍTICA em aberto           |
| 3 | Cobertura de código ≥ 70%                                        |
| 4 | Pipeline CI passando (verde) no branch master                    |
| 5 | Todos os defeitos registrados com relato completo                |

---

## 7. Riscos e Mitigações

| Risco                                           | Probabilidade | Impacto | Mitigação                                               |
|-------------------------------------------------|---------------|---------|----------------------------------------------------------|
| Mudança de requisito durante os testes          | Média         | Alto    | Casos de teste modulares; reteste automatizado via CI    |
| Banco local com estado divergente do CI         | Alta          | Médio   | Usar `python manage.py flush` antes de rodar testes locais |
| Falsos negativos por dados de teste compartilhados | Baixa      | Alto    | Cada TestCase cria seus dados no setUp e usa banco isolado |
| Tempo insuficiente para aceitação com parceiros | Média         | Médio   | Aceitação substituída por testes manuais documentados    |

---

## 8. Papéis e Responsabilidades

| Papel                  | Responsável                     | Atividades                                          |
|------------------------|----------------------------------|-----------------------------------------------------|
| Líder de testes        | Igor Tawan                       | Plano, execução, relatório final                    |
| Desenvolvedor/testador | Leonardo Arrais, Icaro Thaynan       | Escrita de casos e execução                     |
| Revisor de PR          | Integrante que não codificou     | Revisão de código + validação dos testes            |
| Orientador             | Prof. Dr. (IFPI)                 | Validação dos critérios de aceitação                |

---

## 9. Cronograma

| Fase                           | Atividade                                            | Data        |
|--------------------------------|------------------------------------------------------|-------------|
| Planejamento                   | Elaboração do plano de testes                        | 2026-10-28  |
| Design                         | Criação de 20 casos de teste                         | 2026-10-30  |
| Execução — ciclo 1             | Execução de testes automatizados + registro defeitos | 2026-11-01  |
| Execução — ciclo 2 (regressão) | Correção de defeitos + reteste                       | 2026-11-02  |
| Monitoramento                  | Coleta de métricas (meio do ciclo)                   | 2026-11-01  |
| Encerramento                   | Relatório final + parecer de liberação               | 2026-11-03  |

---

## 10. Ferramentas

| Ferramenta        | Uso                                              |
|-------------------|--------------------------------------------------|
| Django TestCase   | Framework de testes de unidade e integração      |
| coverage.py       | Medição de cobertura de código                   |
| GitHub Actions    | Pipeline de CI (execução automática a cada push) |
| drf-spectacular   | Geração de schema OpenAPI para rastreabilidade   |
| django-filter     | Testes de filtragem e paginação                  |
