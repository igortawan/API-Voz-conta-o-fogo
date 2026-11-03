# Script para criar Issues + GitHub Projects board do Voz Contra o Fogo
# Uso: .\criar-quadro-github.ps1 -Token "ghp_SEU_TOKEN_AQUI"
# Gere um token em: https://github.com/settings/tokens (escopos: repo, project)

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$OWNER = "igortawan"
$REPO  = "API-Voz-conta-o-fogo"
$BASE  = "https://api.github.com"
$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "=== Criando Issues das Historias de Usuario ===" -ForegroundColor Cyan

$historias = @(
    @{ title="H01 - Cadastro de usuário cidadão"; body="**Como** cidadão, **quero** me cadastrar na plataforma **para** poder registrar ocorrências.`n`n**Sprint:** 1 | **Pontos:** 3 | **MoSCoW:** Must Have"; labels=@("sprint-1","story") }
    @{ title="H02 - Login e autenticação JWT"; body="**Como** usuário cadastrado, **quero** fazer login **para** receber um token JWT e acessar os endpoints protegidos.`n`n**Sprint:** 1 | **Pontos:** 3 | **MoSCoW:** Must Have"; labels=@("sprint-1","story") }
    @{ title="H03 - Registrar ocorrência de incêndio"; body="**Como** cidadão autenticado, **quero** registrar uma ocorrência com localização GPS **para** notificar as autoridades.`n`n**Sprint:** 1 | **Pontos:** 5 | **MoSCoW:** Must Have"; labels=@("sprint-1","story") }
    @{ title="H04 - Paginação, filtro e ordenação"; body="**Como** autoridade, **quero** filtrar ocorrências por status e município **para** gerenciar a fila de atendimento.`n`n**Sprint:** 1 | **Pontos:** 2 | **MoSCoW:** Must Have"; labels=@("sprint-1","story") }
    @{ title="H05 - Score de prioridade automático"; body="**Como** sistema, **quero** calcular automaticamente o score de prioridade de cada ocorrência **para** ordenar a fila de atendimento.`n`n**Sprint:** 2 | **Pontos:** 5 | **MoSCoW:** Must Have"; labels=@("sprint-2","story","inovacao") }
    @{ title="H06 - Detecção de duplicatas geográficas"; body="**Como** sistema, **quero** identificar ocorrências duplicadas por proximidade geográfica **para** evitar registros redundantes.`n`n**Sprint:** Backlog | **Pontos:** 5 | **MoSCoW:** Should Have"; labels=@("backlog","story","inovacao") }
    @{ title="H07 - Atualizar status de ocorrência"; body="**Como** autoridade, **quero** atualizar o status de uma ocorrência **para** registrar o progresso do atendimento. Cidadão recebe 403.`n`n**Sprint:** 2 | **Pontos:** 3 | **MoSCoW:** Must Have"; labels=@("sprint-2","story") }
    @{ title="H08 - Excluir ocorrência"; body="**Como** autoridade, **quero** excluir uma ocorrência encerrada **para** manter o banco limpo. DELETE retorna 204.`n`n**Sprint:** 2 | **Pontos:** 2 | **MoSCoW:** Should Have"; labels=@("sprint-2","story") }
    @{ title="H09 - Cadastro de alertas"; body="**Como** autoridade, **quero** criar alertas vinculados a ocorrências **para** notificar equipes de campo.`n`n**Sprint:** Backlog | **Pontos:** 5 | **MoSCoW:** Could Have"; labels=@("backlog","story") }
    @{ title="H10 - Gestão de recursos"; body="**Como** administrador, **quero** cadastrar recursos (viaturas, equipes) **para** gerenciar o despacho.`n`n**Sprint:** Backlog | **Pontos:** 5 | **MoSCoW:** Could Have"; labels=@("backlog","story") }
    @{ title="H11 - Verificações de campo"; body="**Como** autoridade em campo, **quero** registrar verificações de ocorrências **para** fechar o ciclo de atendimento.`n`n**Sprint:** Backlog | **Pontos:** 3 | **MoSCoW:** Could Have"; labels=@("backlog","story") }
    @{ title="H12 - Versionamento URI e Cache-Control"; body="**Como** desenvolvedor, **quero** que todos os endpoints estejam em /api/v1/ com Cache-Control **para** garantir conformidade REST.`n`n**Sprint:** 1 | **Pontos:** 1 | **MoSCoW:** Must Have"; labels=@("sprint-1","story","devops") }
    @{ title="H13 - Documentação OpenAPI/Swagger"; body="**Como** consumidor da API, **quero** acessar a documentação interativa em /api/v1/docs/ **para** entender e testar os endpoints.`n`n**Sprint:** 2 | **Pontos:** 3 | **MoSCoW:** Must Have"; labels=@("sprint-2","story","docs") }
    @{ title="H14 - Suíte de testes e pipeline CI"; body="**Como** equipe, **quero** 15 testes automatizados com ≥ 70% de cobertura rodando no GitHub Actions **para** garantir qualidade contínua.`n`n**Sprint:** 2 | **Pontos:** 8 | **MoSCoW:** Must Have"; labels=@("sprint-2","story","ci") }
)

# Criar labels se não existirem
$labels = @("sprint-1","sprint-2","backlog","story","inovacao","devops","docs","ci")
foreach ($label in $labels) {
    $color = switch ($label) {
        "sprint-1"  { "0075ca" }
        "sprint-2"  { "005cc5" }
        "backlog"   { "6e7781" }
        "story"     { "0e8a16" }
        "inovacao"  { "e4e669" }
        "devops"    { "d93f0b" }
        "docs"      { "0075ca" }
        "ci"        { "f29513" }
        default     { "cccccc" }
    }
    $body = @{ name=$label; color=$color; description="" } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$BASE/repos/$OWNER/$REPO/labels" -Method POST -Headers $headers -Body $body -ContentType "application/json" | Out-Null
        Write-Host "  Label criada: $label" -ForegroundColor Green
    } catch {
        Write-Host "  Label ja existe (ok): $label" -ForegroundColor DarkGray
    }
}

# Criar Issues
$issueNumbers = @{}
foreach ($h in $historias) {
    $body = @{
        title  = $h.title
        body   = $h.body
        labels = $h.labels
    } | ConvertTo-Json
    try {
        $issue = Invoke-RestMethod -Uri "$BASE/repos/$OWNER/$REPO/issues" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        $issueNumbers[$h.title] = $issue.number
        Write-Host "  Issue criada: #$($issue.number) — $($h.title)" -ForegroundColor Green
    } catch {
        Write-Host "  Erro ao criar issue: $($h.title)" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Criando GitHub Project (Sprint Board) ===" -ForegroundColor Cyan

# GitHub Projects v2 usa GraphQL
$mutation = @"
mutation {
  createProjectV2(input: {ownerId: "$(
    (Invoke-RestMethod -Uri "$BASE/users/$OWNER" -Headers $headers).node_id
  )", title: "Sprint Board — Voz Contra o Fogo"}) {
    projectV2 {
      id
      url
    }
  }
}
"@

try {
    $projectResp = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method POST -Headers $headers -Body (@{ query=$mutation } | ConvertTo-Json) -ContentType "application/json"
    $projectId  = $projectResp.data.createProjectV2.projectV2.id
    $projectUrl = $projectResp.data.createProjectV2.projectV2.url
    Write-Host "  Projeto criado: $projectUrl" -ForegroundColor Green

    # Adicionar Issues ao projeto
    Write-Host ""
    Write-Host "=== Adicionando Issues ao Projeto ===" -ForegroundColor Cyan
    foreach ($h in $historias) {
        $num = $issueNumbers[$h.title]
        if (-not $num) { continue }
        $issueResp = Invoke-RestMethod -Uri "$BASE/repos/$OWNER/$REPO/issues/$num" -Headers $headers
        $itemMutation = @"
mutation {
  addProjectV2ItemById(input: {projectId: "$projectId", contentId: "$($issueResp.node_id)"}) {
    item { id }
  }
}
"@
        Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method POST -Headers $headers -Body (@{ query=$itemMutation } | ConvertTo-Json) -ContentType "application/json" | Out-Null
        Write-Host "  Adicionada ao projeto: #$num" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Projeto criado com sucesso!" -ForegroundColor Yellow
    Write-Host "URL: $projectUrl" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PROXIMOS PASSOS (manual, 2 minutos):" -ForegroundColor Yellow
    Write-Host "1. Abra o projeto no link acima"
    Write-Host "2. Clique em + para adicionar campo de Status (se nao tiver)"
    Write-Host "3. Renomeie as colunas para:"
    Write-Host "   Todo → Backlog"
    Write-Host "   In Progress → Em andamento / Em revisao"
    Write-Host "   Done → Pronto"
    Write-Host "4. Mova as issues das sprints 1 e 2 para 'Pronto'"
    Write-Host "5. Deixe H06, H09, H10, H11 em 'Backlog'"
    Write-Host ""
    Write-Host "Depois cole o link do projeto no README do repositorio!" -ForegroundColor Yellow

} catch {
    Write-Host "  Erro ao criar projeto GraphQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Crie o projeto manualmente em:" -ForegroundColor Yellow
    Write-Host "  https://github.com/users/igortawan/projects" -ForegroundColor Yellow
    Write-Host "  (as Issues ja foram criadas!)" -ForegroundColor Green
}
