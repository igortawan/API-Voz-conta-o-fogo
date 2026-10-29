// ============================================================================
// admin_controller.dart — migrado para Django API (sem Firebase / Firestore)
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/api/django_report_service.dart';
import '../../../../services/local/hive_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../report/data/models/report_model.dart';

// ── Dados globais ────────────────────────────────────────────────────────────

/// Denúncias carregadas da API Django — usadas por AuthorityPage e AdminPage.
/// O backend filtra por papel: autoridade vê todas; cidadão vê apenas as suas.
final allReportsProvider = FutureProvider<List<ReportModel>>((ref) {
  // Recria o provider sempre que o usuário trocar
  ref.watch(authStateProvider);
  return DjangoReportService.getUserReports();
});

/// Usuários cadastrados — endpoint admin Django.
/// TODO: adicionar endpoint /accounts/admin/users/ no Django para listar todos.
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});

// ── Controle de role ─────────────────────────────────────────────────────────

/// Role do usuário atualmente logado.
///
/// Derivado de [authStateProvider] — reativo a login/logout.
/// NavigationPage escuta este provider para redirecionar automaticamente
/// quando o role mudar (ex: admin promove cidadão para autoridade).
final currentUserRoleProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider);
  return user?.role ?? AppConstants.roleUser;
});

// ── Sistema de notificações da Autoridade ────────────────────────────────────

/// Timestamp do último acesso da autoridade ao painel de alertas.
final authorityLastSeenProvider = StateProvider<DateTime>((ref) {
  final stored = HiveService.getSetting('authority_last_seen');
  if (stored is String) {
    final parsed = DateTime.tryParse(stored);
    if (parsed != null) return parsed;
  }
  return DateTime(2000);
});

/// Quantidade de denúncias criadas APÓS o último acesso da autoridade.
final authorityUnreadCountProvider = Provider<int>((ref) {
  final reports = ref.watch(allReportsProvider).valueOrNull ?? [];
  final lastSeen = ref.watch(authorityLastSeenProvider);
  return reports.where((r) => r.createdAt.isAfter(lastSeen)).length;
});
