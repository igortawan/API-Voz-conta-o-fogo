# API — Voz Contra o Fogo

Backend da aplicação **Voz Contra o Fogo**, desenvolvido no âmbito de uma pesquisa de Iniciação Científica do **IFPI — Campus Paulistana**, com financiamento da **FAPEPI**, voltada ao monitoramento participativo de queimadas na região da Caatinga do semiárido piauiense (Paulistana, Jaicós e Acauã — PI).

---

## Sobre o projeto

O **Voz Contra o Fogo** é uma plataforma de denúncias colaborativas de incêndios florestais. Cidadãos registram ocorrências pelo aplicativo móvel; autoridades ambientais recebem os alertas em tempo real e gerenciam as respostas.

Esta API é responsável por:

- Autenticação de usuários (cidadãos e autoridades) via JWT
- Recebimento, priorização e armazenamento de ocorrências
- Cálculo automático de score de prioridade por ocorrência
- Detecção de denúncias duplicadas por proximidade geográfica
- Envio de notificações push via FCM para autoridades
- Comunicação em tempo real via WebSocket (Django Channels)

---

## Stack

| Tecnologia | Versão |
|---|---|
| Python | 3.11+ |
| Django | 4.2 |
| Django REST Framework | 3.15 |
| SimpleJWT | 5.3 |
| Django Channels | 4.1 |
| Daphne (ASGI) | 4.1 |
| PostgreSQL / SQLite | — |
| Cloudinary | armazenamento de imagens |
| PyFCM | notificações push |

---

## Estrutura dos apps

```
apps/
├── accounts/       # Usuários, autenticação JWT, perfis
├── ocorrencias/    # Denúncias, score, detecção de duplicatas
├── alertas/        # Alertas emitidos pelas autoridades
├── recursos/       # Recursos de combate (viaturas, fontes d'água)
├── verificacoes/   # Verificações de campo pelas autoridades
└── notifications/  # WebSocket consumers e integração FCM
```

---

## Como rodar localmente

### 1. Clone o repositório e entre na branch da API

```bash
git clone https://github.com/igortawan/API-Voz-conta-o-fogo.git
cd API-Voz-conta-o-fogo
```

### 2. Crie o ambiente virtual e instale as dependências

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure as variáveis de ambiente

Copie o `.env.example` para `.env` e preencha os valores:

```bash
cp .env.example .env
```

```env
SECRET_KEY=sua-chave-secreta
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2
DATABASE_URL=sqlite:///db.sqlite3
FCM_SERVER_KEY=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
REDIS_URL=
```

### 4. Execute as migrações e crie um superusuário

```bash
python manage.py migrate
python manage.py createsuperuser
```

### 5. Inicie o servidor

```bash
python manage.py runserver 0.0.0.0:8000
```

A API estará disponível em `http://localhost:8000/api/v1/`.

---

## Documentação interativa (Swagger)

| URL | Descrição |
|-----|-----------|
| `GET /api/v1/docs/` | Swagger UI — interface gráfica para explorar e testar a API |
| `GET /api/v1/redoc/` | ReDoc — documentação em formato legível |
| `GET /api/v1/schema/` | Schema OpenAPI 3.0 em JSON/YAML |

---

## Principais endpoints (`/api/v1/`)

| Método | Endpoint | Auth | Descrição |
|--------|----------|------|-----------|
| `POST` | `/accounts/register/` | Público | Cadastro — retorna 201 ou 409 se e-mail já existe |
| `POST` | `/accounts/login/` | Público | Login — retorna access e refresh token |
| `POST` | `/accounts/token/refresh/` | Público | Renova o access token |
| `GET/PATCH` | `/accounts/me/` | Qualquer | Perfil do usuário autenticado |
| `POST` | `/accounts/logout/` | Qualquer | Invalida o refresh token |
| `POST` | `/accounts/password-reset/` | Público | Gera nova senha temporária |
| `GET` | `/accounts/admin/users/` | Admin | Lista todos os usuários |
| `GET/POST` | `/ocorrencias/` | Qualquer | Listar (paginado, filtro, ordenação) / criar ocorrência |
| `GET` | `/ocorrencias/?status=pendente&ordering=-score_prioridade` | Qualquer | Filtro e ordenação |
| `GET/PATCH/DELETE` | `/ocorrencias/{id}/` | GET: qualquer · PATCH/DELETE: autoridade | Detalhe / atualizar / excluir |
| `GET` | `/ocorrencias/{id}/score/` | Qualquer | Score de prioridade calculado |
| `POST` | `/ocorrencias/detectar-duplicata/` | Qualquer | Detecta denúncia duplicada por proximidade |
| `GET/POST` | `/alertas/` | GET: qualquer · POST: autoridade | Alertas de risco ativos |
| `GET/PATCH/DELETE` | `/alertas/{id}/` | Autoridade | Gerenciar alerta |
| `GET/POST` | `/verificacoes/` | Qualquer | Verificações de campo |
| `GET/POST` | `/recursos/` | Qualquer | Recursos de combate (viaturas, pontos d'água) |

> **Nota:** os mesmos endpoints estão disponíveis em `/api/` (sem versão) para compatibilidade retroativa com o app Flutter.

---

## Rodando os testes

```bash
python manage.py test tests
```

Os 13 testes cobrem: autenticação, criação/listagem/atualização/exclusão de ocorrências, controle de papéis (cidadão vs autoridade), paginação, filtro por status, score, erro padronizado e 409 por e-mail duplicado.

---

## Inovação — diferencial frente a APIs existentes

| API comparada | O que faz | O que a nossa API faz de diferente |
|---|---|---|
| FireBrigade API (genérica) | CRUD de ocorrências | Calcula score de prioridade automaticamente por nível de fogo, proximidade e fumaça |
| INPE Queimadas | Dados satélite, sem participação cidadã | Denúncias colaborativas em tempo real, com WebSocket e push FCM para autoridades |

Eixos de inovação atendidos: **Regra de negócio** (score automático + detecção de duplicatas geográficas) e **Impacto social** (semiárido piauiense, comunidade local).

---

## Notas de desenvolvimento

- O banco padrão para desenvolvimento é **SQLite**. Para produção, configure `DATABASE_URL` com PostgreSQL.
- WebSocket (`/ws/reports/`) requer servidor ASGI (Daphne ou Uvicorn) e Redis configurado em `REDIS_URL`.
- O `runserver` do Django não suporta WebSocket — use `daphne semiaridofogo.asgi:application` em produção.
- Imagens das ocorrências são enviadas diretamente ao **Cloudinary** pelo app móvel; a API recebe apenas as URLs.

---

## Uso de IA no desenvolvimento

Durante o desenvolvimento deste projeto, utilizamos **Inteligência Artificial como ferramenta de orientação técnica** — auxílio em decisões de arquitetura, explicação de conceitos, revisão de abordagens e sugestão de passos a seguir. A escrita do código, as decisões de negócio e a lógica da aplicação foram realizadas pela equipe de desenvolvimento. A IA não gerou o código de forma autônoma.

---

## Equipe

Pesquisa de Iniciação Científica — **IFPI Campus Paulistana**
Financiamento: **FAPEPI**
Bioma: Caatinga · Semiárido Piauiense
