// ============================================================================
// user_model.dart
// ----------------------------------------------------------------------------
// Modelo de dados do usuário do aplicativo.
//
// Representa um documento da coleção `users/{uid}` no Firestore.
// Usado para:
//   • Cache local (Hive) após login bem-sucedido
//   • Exibição de nome/e-mail na tela de perfil
//   • Controle de role (user / autoridade / admin)
//   • Armazenamento do token FCM para notificações push
//
// Nota: o campo `isAdmin` está presente por compatibilidade, mas o controle
// de acesso real é feito pelo campo `role` no Firestore via Riverpod.
// ============================================================================

class UserModel {
  /// ID do usuário (UUID do Django backend).
  final String uid;

  /// E-mail de login (null para usuários anônimos).
  final String? email;

  /// Nome de exibição (informado no cadastro ou via updateDisplayName).
  final String? displayName;

  /// Telefone — campo opcional, não coletado no cadastro atual.
  final String? phone;

  /// URL da foto de perfil — não implementado na versão atual.
  final String? photoUrl;

  /// `true` se o usuário está em modo convidado (Firebase signInAnonymously).
  final bool anonymous;

  /// Token FCM do dispositivo — atualizado a cada login para push notifications.
  final String? fcmToken;

  /// Data de criação da conta.
  final DateTime? createdAt;

  /// Data da última atualização do perfil.
  final DateTime? updatedAt;

  /// Contador de denúncias enviadas — exibido no perfil (futura feature).
  final int totalReports;

  /// Perfil do usuário: 'cidadao' | 'autoridade' | 'admin'.
  /// Definido no Firestore pelo administrador; controla acesso e notificações.
  final String role;

  /// Legado — use `role == 'admin'` no Firestore. Mantido por compatibilidade.
  final bool isAdmin;

  /// Legado — sub-role administrativo. Mantido por compatibilidade.
  final String? adminRole;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.phone,
    this.photoUrl,
    this.anonymous = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.totalReports = 0,
    this.role = 'cidadao',
    this.isAdmin = false,
    this.adminRole,
  });

  // ── Desserialização ─────────────────────────────────────────────────────────

  /// Getter de compatibilidade — alias para [anonymous].
  bool get isAnonymous => anonymous;

  /// Cria um [UserModel] a partir de um Map (Hive local).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      anonymous: map['anonymous'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      totalReports: (map['totalReports'] as num?)?.toInt() ?? 0,
      role: map['role'] as String? ?? 'cidadao',
      isAdmin: map['isAdmin'] as bool? ?? false,
      adminRole: map['adminRole'] as String?,
    );
  }

  // ── Serialização ────────────────────────────────────────────────────────────

  /// Converte para Map para salvar no Firestore ou no Hive.
  /// Datas são omitidas (o Firestore usa FieldValue.serverTimestamp()).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'anonymous': anonymous,
      'fcmToken': fcmToken,
      'totalReports': totalReports,
      'role': role,
      'isAdmin': isAdmin,
      'adminRole': adminRole,
    };
  }

  // ── Cópia com modificações ──────────────────────────────────────────────────

  /// Retorna uma cópia do modelo com os campos fornecidos substituídos.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phone,
    String? photoUrl,
    bool? anonymous,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalReports,
    String? role,
    bool? isAdmin,
    String? adminRole,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      anonymous: anonymous ?? this.anonymous,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalReports: totalReports ?? this.totalReports,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      adminRole: adminRole ?? this.adminRole,
    );
  }

  // ── Computed getters ────────────────────────────────────────────────────────

  /// Retorna o primeiro nome do usuário para exibição na saudação.
  /// Prioridade: displayName > e-mail (antes do @) > 'Cidadão'.
  String get firstName =>
      (displayName ?? email ?? 'Cidadão').split(' ').first;
}
