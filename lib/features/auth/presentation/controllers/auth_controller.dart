// ============================================================================
// auth_controller.dart — migrado para Django JWT (sem Firebase Auth)
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/app_user.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../../../services/firebase/fcm_service.dart';
import '../../../../services/local/hive_service.dart';
import '../../../../core/constants/app_constants.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Usuário atualmente autenticado. null = não logado.
/// Lido por toda a árvore que precisa saber quem está logado.
final authStateProvider = StateProvider<AppUser?>((ref) => null);

/// Controller de autenticação — expõe loading/error durante operações.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref);
});

// ── Controller ────────────────────────────────────────────────────────────────

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null));

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await AuthApiService.login(email: email, password: password);
      final user = await _buildCurrentUser();
      await _afterLogin(user);
      state = AsyncValue.data(user);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // ── Registro ─────────────────────────────────────────────────────────────────

  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await AuthApiService.register(
          email: email, password: password, nome: name);
      final user = await _buildCurrentUser();
      await _afterLogin(user);
      state = AsyncValue.data(user);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // ── Anônimo ──────────────────────────────────────────────────────────────────

  Future<bool> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      // Reutiliza o ID local já salvo ou gera um novo — único por dispositivo.
      // Assim cada usuário anônimo vê apenas as próprias denúncias.
      final existing = HiveService.getSetting('anon_device_id') as String?;
      final anonId = (existing != null && existing.isNotEmpty)
          ? existing
          : 'anon_${const Uuid().v4()}';
      if (existing == null || existing.isEmpty) {
        await HiveService.saveSetting('anon_device_id', anonId);
      }

      final user = AppUser(uid: anonId, isAnonymous: true);
      _ref.read(authStateProvider.notifier).state = user;
      await HiveService.saveUser(
          {'uid': anonId, 'anonymous': true, 'role': 'cidadao'});
      state = AsyncValue.data(user);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // ── Recuperação de senha ─────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    // Implementar endpoint Django /accounts/password-reset/ se necessário.
    // Por ora, apenas ignoramos (Firebase não está mais disponível).
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await FcmService.unsubscribeFromTopic(AppConstants.fcmAuthorityTopic);
    await AuthApiService.logout();
    await HiveService.clearUser();
    // Descarta o ID anônimo local para que a próxima sessão anônima seja nova.
    await HiveService.saveSetting('anon_device_id', '');
    _ref.read(authStateProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  // ── Inicialização de sessão existente ─────────────────────────────────────────

  /// Restaura a sessão a partir do token armazenado (chamado na SplashPage).
  /// Retorna o AppUser se ainda logado, null caso contrário.
  Future<AppUser?> restoreSession() async {
    final isLoggedIn = await AuthApiService.isLoggedIn;
    if (!isLoggedIn) return null;

    // Tenta refresh em background para renovar o access token
    final ok = await AuthApiService.refreshToken();
    if (!ok) {
      await AuthApiService.logout();
      return null;
    }

    final user = await _buildCurrentUser();
    _ref.read(authStateProvider.notifier).state = user;
    state = AsyncValue.data(user);
    return user;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<AppUser> _buildCurrentUser() async {
    final data = await AuthApiService.currentUser;
    return AppUser(
      uid: data['id'] ?? '',
      isAnonymous: false,
      email: data['email'],
      displayName: data['name'],
      role: data['role'] ?? 'cidadao',
    );
  }

  Future<void> _afterLogin(AppUser user) async {
    // Registra token FCM no servidor para push individual
    final fcmToken = await FcmService.getToken();
    if (fcmToken != null) {
      await AuthApiService.updateFcmToken(fcmToken);
    }

    // Tópico legado (mantido para compatibilidade com FCM topic-based)
    if (user.role == AppConstants.roleAuthority) {
      FcmService.subscribeToTopic(AppConstants.fcmAuthorityTopic);
    } else {
      FcmService.unsubscribeFromTopic(AppConstants.fcmAuthorityTopic);
    }

    _ref.read(authStateProvider.notifier).state = user;

    await HiveService.saveUser({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'role': user.role,
      'anonymous': false,
    });
  }
}
