# Product Backlog — Voz Contra o Fogo

**Produto:** API RESTful de monitoramento participativo de queimadas no semiárido piauiense  
**Product Owner:** Igor Tawan  
**Última atualização:** 28/10/2026

---

## Histórias de Usuário

---

### H01 — Cadastro de usuário
**Como** consumidor da API, **quero** criar uma conta com e-mail e senha, **para** acessar os recursos protegidos da plataforma.  
`[Must | 3 pontos | Sprint 1]`

**Critérios de aceitação:**

*Cenário 1 — cadastro com sucesso*
```
Dado que o e-mail não está cadastrado e a senha tem ao menos 8 caracteres
Quando envio POST /api/v1/accounts/register/ com email, nome, password e role
Então recebo 201 com os dados do usuário e os tokens access e refresh
```

*Cenário 2 — e-mail duplicado*
```
Dado que o e-mail já existe no banco
Quando envio POST /api/v1/accounts/register/ com o mesmo e-mail
Então recebo 409 com {"code": "email_conflict", "message": "...", "details": {}}
```

**Rastreabilidade:** req 8, req 9

---

### H02 — Login e renovação de token
**Como** consumidor da API, **quero** autenticar com e-mail e senha, **para** obter um token JWT e acessar endpoints protegidos.  
`[Must | 2 pontos | Sprint 1]`

**Critérios de aceitação:**

*Cenário 1 — login com sucesso*
```
Dado que o usuário existe e está ativo
Quando envio POST /api/v1/accounts/login/ com credenciais válidas
Então recebo 200 com access token e refresh token
```

*Cenário 2 — credenciais inválidas*
```
Dado que a senha está errada
Quando envio POST /api/v1/accounts/login/
Então recebo 401 com {"code": "unauthorized", "message": "...", "details": {}}
```

**Rastreabilidade:** req 8

---

### H03 — Registrar ocorrência de incêndio
**Como** cidadão, **quero** registrar uma ocorrência de queimada com localização e nível de fogo, **para** alertar as autoridades ambientais com informações precisas.  
`[Must | 5 pontos | Sprint 1]`

**Critérios de aceitação:**

*Cenário 1 — criação com sucesso*
```
Dado que possuo token válido e envio latitude, longitude e nivel_fogo válidos
Quando envio POST /api/v1/ocorrencias/
Então recebo 201 com o id da ocorrência e score_prioridade calculado pelo servidor
```

*Cenário 2 — campo obrigatório ausente*
```
Dado que envio o body sem o campo nivel_fogo
Quando envio POST /api/v1/ocorrencias/
Então recebo 400 com {"code": "bad_request", "message": "...", "details": {"nivel_fogo": ["..."]}}
```

**Rastreabilidade:** req 1, req 4, req 9

---

### H04 — Listar ocorrências com paginação, filtro e ordenação
**Como** autoridade ambiental, **quero** consultar as ocorrências com filtros de status e nível de fogo e ordenação por score, **para** priorizar meu atendimento.  
`[Must | 3 pontos | Sprint 1]`

**Critérios de aceitação:**

*Cenário 1 — listagem paginada*
```
Dado que há 30 ocorrências cadastradas e meu token é de autoridade
Quando envio GET /api/v1/ocorrencias/?page=2&ordering=-score_prioridade
Então recebo 200 com {"count": 30, "results": [...10 itens...], "next": "...", "previous": "..."}
E o header Cache-Control: private, max-age=30 está presente
```

*Cenário 2 — filtro por status*
```
Dado que existem ocorrências pendentes e atendidas
Quando envio GET /api/v1/ocorrencias/?status=pendente
Então recebo 200 e todos os itens em results têm status "pendente"
```

**Rastreabilidade:** req 5, req 2

---

### H05 — Score de prioridade automático
**Como** autoridade ambiental, **quero** que cada ocorrência receba um score de prioridade calculado automaticamente pelo servidor, **para** saber quais atender primeiro sem análise manual.  
`[Must | 8 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — score retornado na criação*
```
Dado que envio uma ocorrência com nivel_fogo=critico, ha_fumaca=true, proximo_residencia=true
Quando a ocorrência é criada via POST /api/v1/ocorrencias/
Então o campo score_prioridade no corpo de resposta é maior que 80
```

*Cenário 2 — score consultado isoladamente*
```
Dado que uma ocorrência existe com id válido
Quando envio GET /api/v1/ocorrencias/{id}/score/
Então recebo 200 com {"score": X, "nivel_calculado": "...", "recomendacao": "..."}
```

**Rastreabilidade:** req 7

---

### H06 — Detecção de denúncia duplicada
**Como** administrador da plataforma, **quero** detectar automaticamente denúncias duplicadas por proximidade geográfica, **para** evitar que o mesmo incêndio seja registrado várias vezes.  
`[Should | 5 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — duplicata detectada*
```
Dado que existe uma ocorrência em lat=-7.934, lon=-40.501 registrada há menos de 2 horas
Quando envio POST /api/v1/ocorrencias/detectar-duplicata/ com coordenadas próximas (< 500m)
Então recebo 200 com {"duplicata": true, "ocorrencia_proxima": {...}}
```

*Cenário 2 — sem duplicata*
```
Dado que não existe ocorrência próxima às coordenadas enviadas
Quando envio POST /api/v1/ocorrencias/detectar-duplicata/
Então recebo 200 com {"duplicata": false}
```

**Rastreabilidade:** req 7

---

### H07 — Atualizar status de ocorrência (autoridade)
**Como** autoridade ambiental, **quero** atualizar o status de uma ocorrência para "em_analise" ou "atendida", **para** informar o cidadão sobre o andamento do atendimento.  
`[Must | 3 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — atualização com sucesso*
```
Dado que meu token é de uma autoridade e a ocorrência existe
Quando envio PATCH /api/v1/ocorrencias/{id}/ com {"status": "em_analise"}
Então recebo 200 e o status da ocorrência foi atualizado no banco
```

*Cenário 2 — cidadão tentando atualizar*
```
Dado que meu token é de um cidadão
Quando envio PATCH /api/v1/ocorrencias/{id}/ com {"status": "atendida"}
Então recebo 403 com {"code": "forbidden", "message": "...", "details": {}}
```

**Rastreabilidade:** req 4, req 8

---

### H08 — Excluir ocorrência
**Como** autoridade ambiental, **quero** excluir uma ocorrência indevida ou duplicada, **para** manter a base de dados limpa e confiável.  
`[Should | 2 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — exclusão com sucesso*
```
Dado que meu token é de autoridade e a ocorrência existe
Quando envio DELETE /api/v1/ocorrencias/{id}/
Então recebo 204 sem corpo e a ocorrência não existe mais no banco
```

*Cenário 2 — ocorrência inexistente*
```
Dado que o id informado não existe no banco
Quando envio DELETE /api/v1/ocorrencias/{id}/
Então recebo 404 com {"code": "not_found", "message": "...", "details": {}}
```

**Rastreabilidade:** req 4

---

### H09 — Emitir alerta de risco ambiental
**Como** autoridade ambiental, **quero** emitir alertas de risco para a população de uma área, **para** orientar a evacuação ou cuidados preventivos diante de um incêndio grave.  
`[Must | 3 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — criação de alerta*
```
Dado que meu token é de autoridade
Quando envio POST /api/v1/alertas/ com titulo, nivel_risco e area_afetada
Então recebo 201 e todos os usuários ativos recebem notificação push
```

*Cenário 2 — cidadão tentando criar alerta*
```
Dado que meu token é de cidadão
Quando envio POST /api/v1/alertas/
Então recebo 403 com {"code": "forbidden", "message": "...", "details": {}}
```

**Rastreabilidade:** req 1, req 4, req 8

---

### H10 — Gerenciar recursos de combate
**Como** autoridade ambiental, **quero** cadastrar e consultar recursos de combate (viaturas, pontos d'água), **para** planejar o atendimento a ocorrências críticas.  
`[Should | 3 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — listagem de recursos*
```
Dado que existem recursos cadastrados
Quando envio GET /api/v1/recursos/ com token válido
Então recebo 200 com a lista paginada de recursos disponíveis
```

*Cenário 2 — criação de recurso sem autenticação*
```
Dado que não envio token na requisição
Quando envio POST /api/v1/recursos/
Então recebo 401 com {"code": "unauthorized", "message": "...", "details": {}}
```

**Rastreabilidade:** req 1, req 4

---

### H11 — Registrar verificação de campo
**Como** autoridade ambiental, **quero** registrar verificações de campo feitas no local de uma ocorrência, **para** documentar a situação real e encerrar o atendimento com evidências.  
`[Could | 2 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — registro de verificação*
```
Dado que meu token é de autoridade e a ocorrência existe
Quando envio POST /api/v1/verificacoes/ com ocorrencia_id e descricao
Então recebo 201 com o id da verificação criada
```

*Cenário 2 — ocorrência inexistente*
```
Dado que o ocorrencia_id informado não existe
Quando envio POST /api/v1/verificacoes/
Então recebo 400 com {"code": "bad_request", "message": "...", "details": {}}
```

**Rastreabilidade:** req 1, req 4

---

### H12 — Versionamento de URI e princípios REST
**Como** consumidor da API, **quero** que todos os endpoints estejam disponíveis em `/api/v1/`, **para** ter compatibilidade garantida quando a API evoluir para versões futuras.  
`[Must | 2 pontos | Sprint 1]`

**Critérios de aceitação:**

*Cenário 1 — acesso pela URI versionada*
```
Dado que a API está rodando
Quando envio qualquer requisição para /api/v1/<recurso>/
Então recebo a resposta correta (não 404)
```

*Cenário 2 — header Cache-Control presente*
```
Dado que envio GET /api/v1/ocorrencias/ com token válido
Quando a resposta chega
Então o header Cache-Control: private, max-age=30 está presente
```

**Rastreabilidade:** req 2, req 3, req 6

---

### H13 — Documentação OpenAPI e README
**Como** desenvolvedor que consome a API, **quero** acessar a documentação interativa e instruções de instalação, **para** integrar minha aplicação sem precisar perguntar à equipe.  
`[Must | 3 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — Swagger acessível*
```
Dado que a API está rodando
Quando acesso GET /api/v1/docs/ no navegador
Então vejo o Swagger UI com todos os endpoints documentados
```

*Cenário 2 — README completo*
```
Dado que clono o repositório
Quando sigo as instruções do README
Então consigo rodar a API localmente sem informações adicionais
```

**Rastreabilidade:** req 11

---

### H14 — Suíte de testes automatizados
**Como** desenvolvedor do projeto, **quero** que ao menos 10 testes automatizados cubram os principais fluxos, **para** garantir que regressões sejam detectadas antes do merge.  
`[Must | 5 pontos | Sprint 2]`

**Critérios de aceitação:**

*Cenário 1 — testes passando no CI*
```
Dado que um PR é aberto para a branch master
Quando o pipeline do GitHub Actions executa
Então todos os testes passam e o resultado é verde no PR
```

*Cenário 2 — falha detectada*
```
Dado que um commit quebra o comportamento de um endpoint
Quando o pipeline executa
Então ao menos um teste falha e o merge é bloqueado
```

**Rastreabilidade:** req 12

---

## Rastreabilidade — Requisitos × Histórias

| # | Requisito | Histórias |
|---|---|---|
| 1 | No mínimo 4 recursos | H03, H09, H10, H11 |
| 2 | Cache-Control ou ETag em ao menos um endpoint | H04, H12 |
| 3 | Nomenclatura: plural, minúsculas, hifens | H12 |
| 4 | Verbos e códigos de status corretos | H03, H07, H08, H09, H10, H11 |
| 5 | Paginação, filtro e ordenação | H04 |
| 6 | Versão na URI (/api/v1/) | H12 |
| 7 | Endpoint inovador com regra de negócio | H05, H06 |
| 8 | Autenticação JWT e 2+ papéis | H01, H02, H07, H09 |
| 9 | Validação de entrada e erro padronizado | H01, H03 |
| 10 | Banco de dados real com migrações | H03 |
| 11 | OpenAPI completo e README | H13 |
| 12 | 10+ testes e coleção Postman | H14 |
| 13 | Repositório no GitHub | (todas) |
