/// Representa o usuário autenticado no app — substitui [firebase_auth.User].
///
/// Usado como tipo de [authStateProvider] depois da migração para JWT/Django.
class AppUser {
  final String uid;
  final bool isAnonymous;
  final String? email;
  final String? displayName;
  /// 'cidadao' | 'autoridade' | 'admin'
  final String role;

  const AppUser({
    required this.uid,
    this.isAnonymous = false,
    this.email,
    this.displayName,
    this.role = 'cidadao',
  });

  String get firstName =>
      (displayName ?? email ?? 'Cidadão').split(' ').first;
}
