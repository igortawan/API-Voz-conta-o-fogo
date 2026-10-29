# Acordos da Equipe — Voz Contra o Fogo

**Disciplina:** Engenharia de Software III  
**Professor:** Prof. Me. Julian Rodrigues Valério  
**Equipe:** Voz Contra o Fogo  
**Repositório:** https://github.com/igortawan/API-Voz-conta-o-fogo  

---

## Product Goal

> **Nossa API** ajuda **cidadãos e autoridades ambientais do semiárido piauiense** a **monitorar e responder a queimadas em tempo real**, porque a Caatinga carece de uma plataforma participativa de denúncia com priorização automática de ocorrências.
>
> **Diferente da API do INPE Queimadas** (dados de satélite sem participação cidadã) e da **FireBrigade API** (CRUD genérico sem regras de domínio local), **a nossa** calcula um score de prioridade automático por nível de risco, detecta denúncias duplicadas por proximidade geográfica e notifica autoridades em tempo real via WebSocket e push FCM.

---

## Papéis

| Papel | Sprint 1 | Sprint 2 |
|---|---|---|
| **Product Owner** | Igor Tawan | Igor Tawan |
| **Scrum Master** | [Integrante 2] | Igor Tawan |
| **Developers** | Todos os integrantes | Todos os integrantes |

> O Product Owner permanece o mesmo nas duas sprints. O Scrum Master é uma pessoa diferente em cada sprint.

---

## Definition of Done (DoD)

Uma história só é **Pronta** quando **todos** os itens abaixo forem cumpridos:

- [ ] O código foi integrado por Pull Request revisado e aprovado por outro integrante
- [ ] Os testes automatizados da história foram escritos e passam no CI
- [ ] Os critérios de aceitação da história foram verificados com o Product Owner
- [ ] O endpoint está descrito na especificação OpenAPI (`GET /api/v1/docs/`)
- [ ] A coleção Postman tem a requisição de sucesso e ao menos uma de erro
- [ ] Nenhum segredo (senha, chave, token) foi enviado ao repositório
- [ ] A API continua subindo com as instruções do README após o merge
- [ ] **[item da equipe]** A resposta de erro segue o formato padronizado `{code, message, details}`
- [ ] **[item da equipe]** O código passou por revisão de par (pair review) antes do merge

---

## Acordos de Trabalho

### Acordo 1 — Daily Scrum
- **Quando:** todo dia útil às **20h**
- **Canal:** grupo de WhatsApp da equipe
- **Formato:** cada integrante responde por escrito:
  1. O que fiz desde a última Daily?
  2. O que farei até a próxima Daily?
  3. O que me impede?
- Registro obrigatório em `/scrum/sprint-N/dailies.md`

### Acordo 2 — Pull Requests
- Todo PR deve ter pelo menos **um revisor diferente do autor** antes do merge na `master`
- O título do PR deve referenciar a história: `feat: criar ocorrência (#3)`
- PRs ficam abertos por no máximo **24 horas** antes de serem revisados
- Sem merge com CI falhando

### Acordo 3 — Impedimentos
- Quem travar avisa no grupo **imediatamente**, não espera a próxima Daily
- O Scrum Master tem até **2 horas** para responder e ajudar a desbloquear
- Impedimentos não resolvidos em 1 dia são escalados ao professor (stakeholder)
- O Scrum Master registra cada impedimento em `dailies.md` com data de abertura e resolução

### Acordo 4 — Commits e Branches
- Mensagens de commit referenciam a história: `feat: <o que fez> (#ID)`
- Commits direto na `master` são **proibidos** — todo código entra via PR
- Nome de branch: `feature/H01-cadastro-usuario`, `fix/H03-status-400`
