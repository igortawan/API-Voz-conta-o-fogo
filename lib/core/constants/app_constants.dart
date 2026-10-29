// ============================================================================
// app_constants.dart
// ----------------------------------------------------------------------------
// Constantes globais do aplicativo Voz Contra o Fogo.
//
// Centraliza strings, chaves, IDs e valores numéricos usados em todo o
// projeto. Alterar aqui afeta automaticamente todos os lugares de uso —
// nunca escreva strings mágicas diretamente no código.
//
// Projeto: FAPEPI — IFPI Campus Paulistana, PI.
// ============================================================================

class AppConstants {
  // ── API Django (backend principal) ─────────────────────────────────────────
  // Em desenvolvimento: use o IP local da sua máquina (10.0.2.2 = emulador).
  // Em produção: troque pela URL do Railway/servidor.
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

  // ── Identidade do app ───────────────────────────────────────────────────────

  static const String appName = 'Voz Contra o Fogo';
  static const String appVersion = '1.0.0';
  /// Crédito exibido na tela de perfil e splash.
  static const String ifpiCredit = 'IFPI — Campus Paulistana';

  // ── Coleções do Firestore ───────────────────────────────────────────────────
  // Nomes das coleções raiz no Cloud Firestore.
  // Alterar aqui e no Firebase Console simultaneamente se necessário.

  static const String usersCollection = 'users';
  static const String reportsCollection = 'reports';
  static const String adminsCollection = 'admins';        // legado — não usar
  static const String notificationsCollection = 'notifications';
  static const String logsCollection = 'logs';
  static const String regionsCollection = 'regions';

  // ── Boxes do Hive (armazenamento local) ─────────────────────────────────────
  // Cada box é um arquivo binário separado no storage do dispositivo.

  static const String reportsBox = 'reports_box';         // denúncias offline/cache
  static const String userBox = 'user_box';               // dados do usuário logado
  static const String settingsBox = 'settings_box';       // preferências e timestamps
  static const String pendingSyncBox = 'pending_sync_box';// fila de sincronização offline

  // ── Papéis de usuário (campo `role` em users/{uid}) ──────────────────────────
  // O campo `role` no Firestore define para qual tela o usuário é direcionado.
  //   • roleUser     → NavigationPage (app cidadão)
  //   • roleAuthority → AuthorityPage (painel de autoridade)
  //   • roleAdmin    → AdminPage (painel administrativo)

  static const String roleUser = 'user';
  static const String roleAuthority = 'autoridade';
  static const String roleAdmin = 'admin';

  // ── FCM — Notificações Push ─────────────────────────────────────────────────
  // Tópico ao qual todas as autoridades se inscrevem para receber alertas
  // de novas denúncias. A credencial OAuth2 fica em firebase_service_account.dart.

  static const String fcmAuthorityTopic = 'authority_alerts';

  // ── WorkManager — Sincronização em background ────────────────────────────────
  // Nome e tag da tarefa periódica que sincroniza denúncias offline a cada 15min.

  static const String syncTaskName = 'sync_pending_reports';
  static const String syncTaskTag = 'sync_tag';

  // ── Cloudinary — Upload de imagens ──────────────────────────────────────────
  // Conta gratuita (25GB). Configurações em: cloudinary.com → Settings → Upload.
  // cloudinaryUploadPreset deve ser do tipo "Unsigned" para funcionar sem assinatura.

  static const String cloudinaryCloudName = 'dbniuebhx';
  static const String cloudinaryUploadPreset = 'yuxsd2j6';

  // ── Mapa padrão — Paulistana, Piauí ─────────────────────────────────────────
  // Coordenadas do centro do mapa ao abrir a tela de mapa ou escolher localização.

  static const double defaultLat = -8.1422;
  static const double defaultLng = -41.1509;
  static const double defaultZoom = 13.0;
  static const double brazilZoom = 4.5;   // zoom usado para ver o Brasil inteiro

  // ── Telefones de emergência — Paulistana/PI ──────────────────────────────────
  // Usados nos cards de ligação rápida (info_page, prevention_page, profile_page).

  static const String phoneFireDepartment = '193';     // Corpo de Bombeiros
  static const String phoneCivilDefense = '199';       // Defesa Civil
  static const String phoneMilitaryPolice = '190';     // Polícia Militar
  static const String phoneIbama = '08000618080';      // IBAMA Linha Verde (gratuito)
  static const String phoneSamu = '192';               // SAMU

  // ── INPE — API pública de queimadas ─────────────────────────────────────────
  static const String inpeBaseUrl = 'https://terrabrasilis.dpi.inpe.br';
  static const String inpeQueimadas = 'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/';

  // ── Status das denúncias ─────────────────────────────────────────────────────
  // Valores armazenados no campo `status` da coleção `reports`.
  // Fluxo normal: pendente → enviada → em_analise → atendida (ou rejeitada)

  static const String statusPending = 'pendente';      // salva localmente, não enviada
  static const String statusSent = 'enviada';          // no Firestore, visível à autoridade
  static const String statusAnalyzing = 'em_analise';  // autoridade abrindo investigação
  static const String statusAttended = 'atendida';     // ocorrência resolvida
  static const String statusRejected = 'rejeitada';    // fora de área, duplicada, inválida

  // ── Níveis de incêndio (campo `fireLevel`) ───────────────────────────────────
  // Selecionados pelo usuário ao registrar a denúncia. Determinam a urgência
  // e a cor do marcador no mapa.

  static const String fireLevelSmall = 'Foco Pequeno';
  static const String fireLevelMedium = 'Incêndio Florestal';
  static const String fireLevelNearHome = 'Perto de Residência';
  static const String fireLevelUrgent = 'Urgente';

  // ── Níveis de fumaça (campo `smokeLevel`) ────────────────────────────────────
  static const String smokeLevelLight = 'Leve';
  static const String smokeLevelMedium = 'Média';
  static const String smokeLevelHeavy = 'Alta';

  // ── Compressão de imagens ────────────────────────────────────────────────────
  // Parâmetros usados pelo flutter_image_compress antes de enviar ao Cloudinary.
  // imageQuality = 70% → bom equilíbrio qualidade/tamanho para upload mobile.

  static const int imageQuality = 70;
  static const int imageMaxWidth = 1080;
  static const int imageMaxHeight = 1080;

  // ── Municípios cobertos pelo projeto ─────────────────────────────────────────
  // Abrangência inicial do FAPEPI/IFPI — pode ser expandida em versões futuras.

  static const List<String> coveredMunicipalities = [
    'Paulistana',
    'Jaicós',
    'Acauã',
  ];
}
