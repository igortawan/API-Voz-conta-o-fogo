// ============================================================================
// hive_service.dart
// ----------------------------------------------------------------------------
// Camada de persistência local usando o banco de dados Hive (NoSQL).
//
// O Hive armazena dados como pares chave→valor em arquivos binários no
// storage do dispositivo. É usado como:
//   1. Cache offline de denúncias (reports_box)
//   2. Fila de sincronização pendente (pending_sync_box)
//   3. Cache do usuário logado (user_box)
//   4. Configurações e preferências (settings_box)
//
// Inicialização: deve ser chamada em main() via `await HiveService.init()`
// ANTES do runApp, pois outros serviços dependem dos boxes abertos.
//
// Estratégia offline-first:
//   Denúncia criada → salva no Hive → tenta enviar ao Firestore →
//   se offline → fica na pendingSyncBox → WorkManager sincroniza quando
//   houver conexão (a cada 15 minutos).
// ============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class HiveService {
  // ── Inicialização ───────────────────────────────────────────────────────────

  /// Inicializa o Hive e abre todos os boxes necessários.
  /// Deve ser chamado UMA VEZ em main() antes do runApp.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(AppConstants.reportsBox);
    await Hive.openBox<Map>(AppConstants.userBox);
    await Hive.openBox<Map>(AppConstants.settingsBox);
    await Hive.openBox<Map>(AppConstants.pendingSyncBox);
  }

  // ── Referências diretas aos boxes ───────────────────────────────────────────
  // Use estas propriedades em vez de chamar Hive.box() diretamente nos serviços.

  /// Box de denúncias — cache local de todos os reports (online e offline).
  static Box<Map> get reportsBox => Hive.box<Map>(AppConstants.reportsBox);

  /// Box do usuário — cache do perfil do usuário logado.
  static Box<Map> get userBox => Hive.box<Map>(AppConstants.userBox);

  /// Box de configurações — preferências e timestamps (ex.: authority_last_seen).
  static Box<Map> get settingsBox => Hive.box<Map>(AppConstants.settingsBox);

  /// Box de sincronização pendente — IDs de denúncias aguardando envio ao Firestore.
  static Box<Map> get pendingSyncBox =>
      Hive.box<Map>(AppConstants.pendingSyncBox);

  // ── Operações com Relatórios ────────────────────────────────────────────────

  /// Salva ou atualiza uma denúncia localmente usando seu `id` como chave.
  static Future<void> saveReport(Map<String, dynamic> report) async {
    final id = report['id'] as String;
    await reportsBox.put(id, report);
  }

  /// Remove uma denúncia do armazenamento local pelo seu ID.
  static Future<void> deleteReport(String id) async {
    await reportsBox.delete(id);
  }

  /// Retorna todas as denúncias locais ordenadas por data de criação (mais recente primeiro).
  static List<Map<String, dynamic>> getAllReports() {
    return reportsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) {
        // Ordena por createdAt (ISO 8601) do mais recente para o mais antigo
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
  }

  /// Retorna apenas as denúncias que ainda não foram sincronizadas com o Firestore.
  static List<Map<String, dynamic>> getPendingReports() {
    return getAllReports()
        .where((r) => r['synced'] == false || r['synced'] == null)
        .toList();
  }

  /// Marca uma denúncia como sincronizada e atualiza seu status para 'enviada'.
  /// Chamado pelo [SyncService] após upload bem-sucedido ao Firestore.
  static Future<void> markReportAsSynced(String id) async {
    final report = reportsBox.get(id);
    if (report != null) {
      final updated = Map<String, dynamic>.from(report);
      updated['synced'] = true;
      updated['status'] = AppConstants.statusSent;
      await reportsBox.put(id, updated);
    }
  }

  // ── Fila de Sincronização Pendente ──────────────────────────────────────────

  /// Adiciona o ID de uma denúncia à fila de sincronização.
  /// Chamado quando uma denúncia é criada offline.
  static Future<void> addToPendingSync(String reportId) async {
    await pendingSyncBox.put(
      reportId,
      {'reportId': reportId, 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Remove um ID da fila após sincronização bem-sucedida.
  static Future<void> removeFromPendingSync(String reportId) async {
    await pendingSyncBox.delete(reportId);
  }

  /// Retorna a lista de IDs pendentes de sincronização.
  static List<String> getPendingSyncIds() {
    return pendingSyncBox.keys.cast<String>().toList();
  }

  // ── Cache do Usuário ────────────────────────────────────────────────────────

  /// Salva o perfil do usuário logado localmente (para exibição offline).
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await userBox.put('current_user', user);
  }

  /// Retorna o perfil do usuário em cache, ou `null` se não houver dados.
  static Map<String, dynamic>? getUser() {
    final data = userBox.get('current_user');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Limpa o cache do usuário (chamado no logout).
  static Future<void> clearUser() async {
    await userBox.delete('current_user');
  }

  // ── Configurações e Preferências ────────────────────────────────────────────

  /// Salva um valor de configuração identificado por [key].
  /// Suporta qualquer tipo primitivo (String, int, bool, DateTime…).
  ///
  /// Exemplo:
  /// ```dart
  /// await HiveService.saveSetting('authority_last_seen', DateTime.now().toIso8601String());
  /// ```
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, {key: value});
  }

  /// Lê um valor de configuração pelo [key].
  /// Retorna [defaultValue] se a chave não existir.
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = settingsBox.get(key);
    return box != null ? box[key] : defaultValue;
  }

  // ── Limpeza geral ────────────────────────────────────────────────────────────

  /// Remove todos os dados de reports, usuário e fila de sincronização.
  /// NÃO limpa as configurações (settings_box).
  /// Chamado em logout completo se necessário.
  static Future<void> clearAll() async {
    await reportsBox.clear();
    await userBox.clear();
    await pendingSyncBox.clear();
  }
}
