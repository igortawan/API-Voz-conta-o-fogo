// firestore_service.dart — shim sem Cloud Firestore; delega ao Django.
// Mantido para compatibilidade de importações nas páginas legadas.
// Funcionalidades admin/autoridade retornam dados vazios até a migração completa.

import '../../core/constants/app_constants.dart';
import '../../features/report/data/models/report_model.dart';
import '../api/django_report_service.dart';
import '../local/hive_service.dart';

class FirestoreService {
  // ── Reports ──────────────────────────────────────────────────────────────────

  static Future<String> createReport(Map<String, dynamic> data) async {
    try {
      final report = ReportModel.fromMap(data);
      final created = await DjangoReportService.createReport(report);
      return created?.id ?? (data['id'] as String? ?? '');
    } catch (_) {
      return data['id'] as String? ?? '';
    }
  }

  static Future<void> updateReport(String id, Map<String, dynamic> data) async {
    // TODO: PATCH /ocorrencias/{id}/
  }

  static Future<Map<String, dynamic>?> getReport(String id) async {
    // TODO: GET /ocorrencias/{id}/
    return null;
  }

  // Stream de reports do usuário — agora gerenciado por userReportsProvider.
  static Stream<List<Map<String, dynamic>>> getUserReportsStream(String userId) =>
      Stream.value([]);

  // Streams para admin/autoridade — migração futura.
  static Stream<List<Map<String, dynamic>>> getAllReportsStream() =>
      Stream.value([]);

  static Stream<List<Map<String, dynamic>>> getActiveReportsStream() =>
      Stream.value([]);

  // ── Usuários ──────────────────────────────────────────────────────────────────

  static Future<void> createOrUpdateUser(
      String uid, Map<String, dynamic> data) async {}

  static Future<Map<String, dynamic>?> getUser(String uid) async => null;

  static Future<void> saveFcmToken(String uid, String token) async {}

  static Future<String> getUserRole(String uid) async {
    return HiveService.getUser()?['role'] as String? ?? AppConstants.roleUser;
  }

  static Stream<String> getUserRoleStream(String uid) {
    final role =
        HiveService.getUser()?['role'] as String? ?? AppConstants.roleUser;
    return Stream.value(role);
  }

  static Future<bool> isAdmin(String uid) async => false;

  static Future<void> setUserRole(String uid, String role) async {}

  static Stream<List<Map<String, dynamic>>> getUsersStream() =>
      Stream.value([]);

  // ── Status de denúncias (autoridade) ─────────────────────────────────────────

  static Future<void> updateReportStatus(
    String reportId,
    String newStatus,
    String respondedByUid, {
    String? observations,
  }) async {
    // TODO: PATCH /ocorrencias/{reportId}/ via DjangoReportService
  }

  // ── Notificações ──────────────────────────────────────────────────────────────

  static Future<void> createNotification(Map<String, dynamic> data) async {}

  static Future<void> createUserNotification(
    String userId, {
    required String title,
    required String message,
    required String reportId,
    required String newStatus,
  }) async {}

  static Stream<List<Map<String, dynamic>>> getUserNotificationsStream(
          String userId) =>
      Stream.value([]);

  static Future<void> markNotificationRead(String docId) async {}

  static Future<void> markAllNotificationsRead(String userId) async {}

  // ── Logs ──────────────────────────────────────────────────────────────────────

  static Future<void> log(String event, Map<String, dynamic> data) async {}
}
