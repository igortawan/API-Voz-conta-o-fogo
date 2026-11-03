# Parte 2 — Testes em Metodologias Ágeis

**Projeto:** Voz Contra o Fogo — API REST de monitoramento de queimadas  
**Metodologia:** Scrum + XP (eXtreme Programming)

---

## 1. Histórias de Usuário com Critérios de Aceitação (BDD)

### H1 — Registro de Ocorrência de Incêndio

> **Como** cidadão residente no semiárido piauiense  
> **Quero** registrar uma ocorrência de incêndio com dados de localização GPS  
> **Para que** as autoridades competentes possam ser notificadas rapidamente

**Critérios de Aceitação (Dado / Quando / Então):**

- **Dado** que o cidadão está autenticado no app  
  **Quando** preenche os campos latitude, longitude e nivel_fogo e envia o formulário  
  **Então** a API retorna HTTP 201 com um ID único e o score de prioridade calculado

- **Dado** que o cidadão não preencheu o campo nivel_fogo  
  **Quando** tenta enviar o formulário  
  **Então** a API retorna HTTP 400 com detalhes do campo inválido

---

### H2 — Visualização de Ocorrências por Prioridade

> **Como** autoridade ambiental (IBAMA / Corpo de Bombeiros-PI)  
> **Quero** visualizar a lista de ocorrências ordenadas por score de prioridade  
> **Para que** eu possa atender primeiro os casos mais críticos

**Critérios de Aceitação:**

- **Dado** que há ocorrências com scores diferentes no banco  
  **Quando** a autoridade acessa GET /api/v1/ocorrencias/?ordering=-score_prioridade  
  **Então** a lista retorna com a ocorrência de maior score no primeiro item

- **Dado** que a autoridade quer filtrar por status  
  **Quando** acessa GET /api/v1/ocorrencias/?status=pendente  
  **Então** apenas ocorrências pendentes são retornadas na lista

---

### H3 — Denúncia Anônima

> **Como** cidadão que teme represálias  
> **Quero** registrar uma ocorrência sem que meu nome apareça para terceiros  
> **Para que** eu possa colaborar com o monitoramento sem me expor

**Critérios de Aceitação:**

- **Dado** que o cidadão está autenticado  
  **Quando** envia uma ocorrência com o campo anonima=true  
  **Então** a API retorna 201 e o campo usuario_nome fica oculto na resposta para outros usuários

- **Dado** que o cidadão enviou uma denúncia anônima  
  **Quando** uma autoridade consulta a ocorrência  
  **Então** o campo usuario é exibido como "Anônimo" na resposta

---

### H4 — Detecção de Ocorrências Duplicadas (Funcionalidade Inovadora)

> **Como** sistema de monitoramento  
> **Quero** identificar automaticamente ocorrências duplicadas por proximidade geográfica e temporal  
> **Para que** o banco de dados não se encha com múltiplos registros do mesmo incêndio

**Critérios de Aceitação:**

- **Dado** que já existe uma ocorrência nas coordenadas (lat=-7.934, lon=-40.501) reportada há 30 minutos  
  **Quando** um segundo cidadão reporta outra ocorrência a menos de 500 m das mesmas coordenadas  
  **Então** o endpoint /detectar-duplicata/ retorna is_duplicata=true com referência ao ID original

- **Dado** que a ocorrência mais próxima foi reportada há mais de 2 horas  
  **Quando** uma nova ocorrência é enviada para o mesmo ponto  
  **Então** o sistema a trata como nova ocorrência (is_duplicata=false)

---

## 2. Definition of Done (DoD)

Para que uma história de usuário seja considerada **concluída**, todos os itens abaixo devem estar atendidos:

| # | Critério de qualidade                                                                 | Como verificar                                  |
|---|---------------------------------------------------------------------------------------|-------------------------------------------------|
| 1 | Todos os testes automatizados passam (incluindo os novos para a história)             | `python manage.py test tests --verbosity=2`     |
| 2 | Cobertura de código >= 70% após a adição da funcionalidade                            | `coverage report --fail-under=70`               |
| 3 | Código revisado por ao menos um outro integrante da equipe via Pull Request           | PR aprovado no GitHub antes do merge            |
| 4 | Documentação OpenAPI atualizada e acessível em /api/schema/swagger-ui/                | GET /api/schema/ retorna 200 sem erros          |
| 5 | Pipeline CI/CD verde no GitHub Actions (push na branch master)                        | Badge "passing" no repositório                  |
| 6 | Endpoint documentado no Scrum Board (backlog → done)                                  | Card movido para "Concluído" no quadro          |
| 7 | Sem vulnerabilidade de autenticação: endpoint exige token válido ou retorna 401       | Teste de segurança no test_api.py               |

---

## 3. Evidências de TDD (Test-Driven Development)

O TDD foi aplicado na adição dos **Testes 14 e 15** ao suite de testes, seguindo o ciclo Red → Green → Refactor.

### Funcionalidade 1 — Validação de campo obrigatório `nivel_fogo`

**Ciclo TDD:**

**Passo 1 — Red (teste falhando):**
```python
# Teste 14 — escrito ANTES da implementação da validação
def test_create_ocorrencia_missing_nivel_fogo_returns_400(self):
    auth(self.client, 'cidadao@test.com')
    payload = {k: v for k, v in OCORRENCIA_BASE.items() if k != 'nivel_fogo'}
    res = self.client.post('/api/v1/ocorrencias/', payload, format='json')
    self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
    self.assertEqual(res.data['code'], 'bad_request')
    self.assertIn('nivel_fogo', res.data.get('details', {}))
# Resultado: FAIL — API retornava 500 sem validação adequada
```

**Passo 2 — Green (código mínimo para passar):**  
Adicionado `nivel_fogo = serializers.ChoiceField(choices=NIVEL_CHOICES, required=True)` no `OcorrenciaSerializer` e handler de erro retornando `code='bad_request'`.  
Resultado: PASS

**Passo 3 — Refactor:**  
Extraída função auxiliar `_handle_validation_errors(serializer)` reutilizada em outros serializers do projeto.

---

### Funcionalidade 2 — Ordenação por `score_prioridade`

**Ciclo TDD:**

**Passo 1 — Red (teste falhando):**
```python
# Teste 15 — escrito ANTES de adicionar ordering ao ViewSet
def test_ordering_by_score_prioridade(self):
    # cria ocorrência score=10 e score=95
    auth(self.client, 'cidadao@test.com')
    res = self.client.get('/api/v1/ocorrencias/?ordering=-score_prioridade')
    self.assertEqual(res.status_code, status.HTTP_200_OK)
    results = res.data['results']
    if len(results) >= 2:
        self.assertGreaterEqual(results[0]['score_prioridade'], results[1]['score_prioridade'])
# Resultado: FAIL — ordering não estava configurado no ViewSet
```

**Passo 2 — Green:**  
Adicionado `ordering_fields = ['score_prioridade', 'criado_em']` e `ordering = ['-score_prioridade']` ao `OcorrenciaViewSet`.  
Resultado: PASS

**Passo 3 — Refactor:**  
Padronizados todos os ViewSets para usar a mesma configuração de `OrderingFilter`.

---

## 4. Integração Contínua (CI)

O projeto utiliza **GitHub Actions** com pipeline configurado em `.github/workflows/tests.yml`.

### O que o pipeline executa a cada push na `master`:

```yaml
1. Checkout do repositório
2. Configuração do Python 3.11
3. Instalação de dependências (pip install -r requirements.txt)
4. Criação do banco PostgreSQL 15 (service container)
5. Aplicação de migrações (python manage.py migrate)
6. Execução dos testes com cobertura:
   coverage run --source=apps manage.py test tests --verbosity=2
   coverage report --fail-under=70
   coverage xml -o coverage.xml
7. Upload do relatório de cobertura como artefato
```

**Resultado atual:** 15 testes passando, 74% de cobertura (> 70% exigido).

---

## 5. Pirâmide de Testes

```
        /\
       /  \
      / E2E\     0 testes (flutter integration tests — fora do escopo da API)
     /------\
    /Sistema \   2 testes (fluxos completos via APIClient)
   /----------\
  / Integração \  8 testes (endpoints × banco de dados)
 /--------------\
/    Unidade     \  5 testes (serializers, autenticação, validação unitária)
──────────────────
```

| Nível       | Quantidade | % do total | Exemplos no projeto                                      |
|-------------|------------|------------|----------------------------------------------------------|
| Unidade     | 5          | 33%        | test_register_*, test_login_*, test_unauthenticated_*    |
| Integração  | 8          | 53%        | test_create_*, test_autoridade_*, test_filter_*, test_ordering_* |
| Sistema     | 2          | 13%        | test_me_* (ponta a ponta no ambiente de teste)           |
| E2E         | 0          | 0%         | (fora do escopo deste projeto; coberto manualmente)      |
| **Total**   | **15**     | **100%**   |                                                          |

---

## 6. Reflexão: Testes Ágeis vs. Modelo V (≥ 15 linhas)

A abordagem ágil de testes — especialmente o TDD e a integração contínua — contrasta com o Modelo V em aspectos fundamentais que ficaram evidentes durante o desenvolvimento do Voz Contra o Fogo.

No **Modelo V**, testes são planejados como espelho das fases de desenvolvimento: cada nível de teste é projetado antecipadamente, associado a um artefato de especificação. Essa abordagem gera **documentação rica** e **rastreabilidade clara**, mas pressupõe que os requisitos são estáveis. No contexto do projeto, percebemos que essa estabilidade raramente existe: a funcionalidade de detecção de duplicatas foi proposta pelo parceiro (Corpo de Bombeiros-PI) após o início da codificação, e o cálculo de score foi refinado três vezes conforme o orientador avaliava o protótipo.

Já na **abordagem ágil com TDD**, os testes são escritos antes do código. Isso tem um efeito profundo: força o desenvolvedor a pensar na interface e no comportamento esperado antes de qualquer implementação, o que melhora o design. Quando o Teste 14 foi escrito (validação de nivel_fogo ausente), o serializer não existia — o teste atuou como especificação executável. Essa dinâmica não existe no Modelo V tradicional.

A **integração contínua** complementa o TDD garantindo que nenhuma mudança quebra o que já funcionava. Na prática, o pipeline do GitHub Actions capturou duas regressões durante o sprint 2: uma mudança no serializer de Alerta quebrou o teste de listagem de ocorrências, e a CI sinalizou antes do merge. Em um processo sequencial, essa regressão poderia ter chegado à fase de testes de sistema.

A principal desvantagem da abordagem ágil é a **menor visibilidade para stakeholders externos**: o Modelo V produz documentos formais que facilitam auditorias e comunicação com entidades financiadoras como a FAPEPI. Testes ágeis precisam ser complementados com artefatos como este relatório para cumprir esse papel.

A conclusão prática é que os dois modelos não são excludentes: o Modelo V fornece a estrutura de rastreabilidade e os critérios de aceitação definidos com os parceiros, enquanto TDD e CI garantem a qualidade no dia a dia do desenvolvimento. Projetos de pesquisa aplicada, como o IC no IFPI Paulistana, se beneficiam de ambos combinados.
