// auth_service.dart — shim sem Firebase Auth; lê do cache Hive (JWT session).
// Mantido para compatibilidade de importações nas páginas legadas.

import '../../features/auth/data/models/user_model.dart';
import '../local/hive_service.dart';

class AuthService {
  // ── Getters síncronos (lêem do cache Hive) ───────────────────────────────────

  static UserModel? get currentUser {
    final data = HiveService.getUser();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  static String? get currentUid {
    final uid = HiveService.getUser()?['uid'] as String?;
    // UIDs anônimos começam com 'anon_' — não são contas reais no servidor.
    return (uid == null || uid.isEmpty || uid.startsWith('anon_')) ? null : uid;
  }

  static bool get isLoggedIn => currentUid != null;

  static bool get isAnonymous =>
      HiveService.getUser()?['anonymous'] as bool? ?? true;

  // authStateChanges não é mais usado (substituído por authStateProvider).
  // Retorna stream vazio para não quebrar compilação de código legado.
  static Stream<Null> get authStateChanges => const Stream.empty();

  // ── Stubs (operações agora feitas via AuthController / AuthApiService) ────────

  static Future<void> signOut() async {}
  static Future<void> updateDisplayName(String name) async {}
  static Future<void> sendPasswordResetEmail(String email) async {}
}
