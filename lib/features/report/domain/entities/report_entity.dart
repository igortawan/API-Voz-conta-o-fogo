// ============================================================================
// report_entity.dart
// ----------------------------------------------------------------------------
// Entidade de domínio de uma denúncia de incêndio/queimada.
//
// Esta classe representa o "contrato" dos dados de uma denúncia no domínio
// da aplicação — independente de Firestore, Hive ou qualquer infraestrutura.
//
// [ReportModel] estende esta classe adicionando fromMap/toMap para
// serialização. Outros serviços (controllers, UI) trabalham com [ReportEntity]
// ou [ReportModel] diretamente.
//
// Ciclo de vida de uma denúncia:
//   1. Criada no [ReportController] (pendente + synced=false)
//   2. Se online → enviada ao Firestore (status=enviada, synced=true)
//   3. Se offline → salva no Hive (status=pendente, synced=false)
//   4. SyncService sincroniza quando houver conexão
//   5. Autoridade muda o status (em_analise → atendida/rejeitada)
// ============================================================================

class ReportEntity {
  // ── Identificação ───────────────────────────────────────────────────────────

  /// ID único da denúncia (UUID v4 gerado no dispositivo).
  final String id;

  /// Momento da criação (local — ajustado para serverTimestamp no Firestore).
  final DateTime createdAt;

  /// Momento da última atualização de status pela autoridade.
  final DateTime? updatedAt;

  // ── Usuário ─────────────────────────────────────────────────────────────────

  /// UID do usuário que registrou. 'anonymous' para denúncias sem cadastro.
  final String userId;

  /// `true` se o usuário optou por não identificar seu nome na denúncia.
  final bool anonymous;

  // ── Localização ─────────────────────────────────────────────────────────────

  /// Latitude do foco de incêndio (WGS-84).
  final double latitude;

  /// Longitude do foco de incêndio (WGS-84).
  final double longitude;

  /// Endereço geocodificado (ex.: "Zona Rural, Paulistana, PI").
  /// Pode ser null se o geocoding falhou ou foi desativado.
  final String? address;

  // ── Dados do incêndio ───────────────────────────────────────────────────────

  /// Descrição livre do usuário sobre o foco (onde está, o que observou, etc.).
  final String description;

  /// Nível de intensidade do foco — ver [AppConstants.fireLevel*].
  /// Valores: 'Foco Pequeno', 'Incêndio Florestal', 'Perto de Residência', 'Urgente'.
  final String fireLevel;

  /// Nível de fumaça observado — ver [AppConstants.smokeLevel*].
  /// Valores: 'Leve', 'Média', 'Alta'.
  final String smokeLevel;

  /// Classificação de risco — geralmente repetição do fireLevel ou complemento.
  final String riskLevel;

  // ── Imagens ─────────────────────────────────────────────────────────────────

  /// URLs das imagens enviadas ao Cloudinary (disponíveis online).
  final List<String> images;

  /// Caminhos locais das imagens no dispositivo (disponíveis offline).
  /// São removidos após sincronização bem-sucedida com o Cloudinary.
  final List<String> localImages;

  // ── Status e controle ───────────────────────────────────────────────────────

  /// Status atual no fluxo de atendimento — ver [AppConstants.status*].
  final String status;

  /// `true` se a denúncia foi criada enquanto o dispositivo estava offline.
  final bool offlineCreated;

  /// `true` se já foi sincronizada com o Firestore.
  final bool synced;

  // ── Campos de resposta da autoridade ────────────────────────────────────────

  /// Observação deixada pela autoridade ao alterar o status.
  final String? observations;

  /// UID da autoridade que respondeu à denúncia.
  final String? respondedBy;

  /// Score de prioridade calculado pelo backend Django (0–100).
  /// null para denúncias locais não sincronizadas.
  final int? score;

  const ReportEntity({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.anonymous,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.description,
    required this.fireLevel,
    required this.smokeLevel,
    required this.riskLevel,
    this.images = const [],
    this.localImages = const [],
    required this.status,
    this.offlineCreated = false,
    this.synced = true,
    this.observations,
    this.respondedBy,
    this.score,
  });

  // ── Computed getters ────────────────────────────────────────────────────────

  /// `true` se a denúncia está aguardando processamento pela autoridade.
  bool get isPending => status == 'pendente';

  /// `true` se foi enviada ao Firestore e está visível à autoridade.
  bool get isSent => status == 'enviada';

  /// `true` se a autoridade está investigando a ocorrência.
  bool get isAnalyzing => status == 'em_analise';

  /// `true` se a ocorrência foi atendida pelos bombeiros/autoridade.
  bool get isAttended => status == 'atendida';

  /// `true` se o fireLevel é 'Urgente' — exige atenção imediata.
  bool get isUrgent => fireLevel == 'Urgente';

  /// `true` se o incêndio está próximo a residências — risco a vidas.
  bool get isNearHome =>
      riskLevel.contains('Residência') || riskLevel == 'Perto de Residência';
}
