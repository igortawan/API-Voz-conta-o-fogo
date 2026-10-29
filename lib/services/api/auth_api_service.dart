import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Serviço de autenticação JWT — substitui Firebase Auth.
///
/// Tokens armazenados de forma segura via flutter_secure_storage.
/// O access token dura 8h; o refresh token dura 30 dias.
class AuthApiService {
  static const _storage = FlutterSecureStorage();
  static const _keyAccess = 'jwt_access';
  static const _keyRefresh = 'jwt_refresh';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';

  static const _base = AppConstants.apiBaseUrl;

  // ── Getters ─────────────────────────────────────────────────────────────────

  static Future<String?> get accessToken => _storage.read(key: _keyAccess);
  static Future<String?> get userId => _storage.read(key: _keyUserId);
  static Future<String?> get userRole => _storage.read(key: _keyUserRole);
  static Future<bool> get isLoggedIn async => (await accessToken) != null;

  static Future<Map<String, String?>> get currentUser async => {
    'id': await _storage.read(key: _keyUserId),
    'role': await _storage.read(key: _keyUserRole),
    'name': await _storage.read(key: _keyUserName),
    'email': await _storage.read(key: _keyUserEmail),
  };

  // ── Headers ─────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> get authHeaders async {
    final token = await accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Registro ─────────────────────────────────────────────────────────────────

  static Future<void> register({
    required String email,
    required String password,
    required String nome,
    String role = 'cidadao',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/accounts/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'nome': nome, 'role': role}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['email']?.first ?? body['password']?.first ?? 'Erro no cadastro');
    }

    final data = jsonDecode(res.body);
    await _saveSession(data);
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('E-mail ou senha incorretos');
    }

    final data = jsonDecode(res.body);
    // Login retorna access + refresh; busca perfil completo em seguida
    await _storage.write(key: _keyAccess, value: data['access']);
    await _storage.write(key: _keyRefresh, value: data['refresh']);
    await _fetchAndSaveProfile();
  }

  // ── Refresh token ─────────────────────────────────────────────────────────────

  static Future<bool> refreshToken() async {
    final refresh = await _storage.read(key: _keyRefresh);
    if (refresh == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_base/accounts/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        await logout();
        return false;
      }
      final data = jsonDecode(res.body);
      await _storage.write(key: _keyAccess, value: data['access']);
      if (data['refresh'] != null) {
        await _storage.write(key: _keyRefresh, value: data['refresh']);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ── FCM token ─────────────────────────────────────────────────────────────────

  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      final headers = await authHeaders;
      await http.patch(
        Uri.parse('$_base/accounts/me/'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Helpers privados ─────────────────────────────────────────────────────────

  static Future<void> _fetchAndSaveProfile() async {
    final headers = await authHeaders;
    final res = await http.get(
      Uri.parse('$_base/accounts/me/'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final user = jsonDecode(res.body);
      await _storage.write(key: _keyUserId, value: user['id'].toString());
      await _storage.write(key: _keyUserRole, value: user['role'].toString());
      await _storage.write(key: _keyUserName, value: user['nome'].toString());
      await _storage.write(key: _keyUserEmail, value: user['email'].toString());
    }
  }

  static Future<void> _saveSession(Map data) async {
    await _storage.write(key: _keyAccess, value: data['access']);
    await _storage.write(key: _keyRefresh, value: data['refresh']);
    final user = data['user'];
    await _storage.write(key: _keyUserId, value: user['id'].toString());
    await _storage.write(key: _keyUserRole, value: user['role'].toString());
    await _storage.write(key: _keyUserName, value: user['nome'].toString());
    await _storage.write(key: _keyUserEmail, value: user['email'].toString());
  }
}
