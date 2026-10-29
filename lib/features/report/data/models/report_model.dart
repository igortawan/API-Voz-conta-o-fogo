// ============================================================================
// report_model.dart
// ----------------------------------------------------------------------------
// Modelo de dados de uma denúncia — camada de infraestrutura.
//
// Estende [ReportEntity] (domínio puro) adicionando serialização
// para/do Firestore e Hive via `fromMap` / `toMap`.
//
// É a classe concreta usada em toda a camada de dados e apresentação.
// Os controllers e widgets trabalham com [ReportModel] diretamente.
// ============================================================================

import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.createdAt,
    required super.userId,
    required super.anonymous,
    required super.latitude,
    required super.longitude,
    super.address,
    required super.description,
    required super.fireLevel,
    required super.smokeLevel,
    required super.riskLevel,
    super.images,
    required super.status,
    super.offlineCreated,
    super.synced,
    super.updatedAt,
    super.observations,
    super.respondedBy,
    super.localImages,
    super.score,
  });

  // ── Desserialização ─────────────────────────────────────────────────────────

  /// Cria um [ReportModel] a partir de um Map (Hive ou cache local).
  factory ReportModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ReportModel(
      id: map['id'] as String? ?? '',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']),
      userId: map['userId'] as String? ?? '',
      anonymous: map['anonymous'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String?,
      description: map['description'] as String? ?? '',
      fireLevel: map['fireLevel'] as String? ?? '',
      smokeLevel: map['smokeLevel'] as String? ?? '',
      riskLevel: map['riskLevel'] as String? ?? '',
      images: List<String>.from(map['images'] ?? []),
      localImages: List<String>.from(map['localImages'] ?? []),
      status: map['status'] as String? ?? 'pendente',
      offlineCreated: map['offlineCreated'] as bool? ?? false,
      synced: map['synced'] as bool? ?? true,
      observations: map['observations'] as String?,
      respondedBy: map['respondedBy'] as String?,
      score: map['score'] as int?,
    );
  }

  /// Cria um [ReportModel] a partir da resposta JSON do backend Django.
  /// Os nomes de campo do Django (snake_case) são mapeados para o padrão Flutter.
  factory ReportModel.fromDjangoMap(Map<String, dynamic> map) {
    // Mapeia nivel_fogo do Django para fireLevel do Flutter
    const nivelMap = {
      'baixo': 'fireLevelSmall', 'medio': 'fireLevelMedium',
      'alto': 'fireLevelNearHome', 'critico': 'fireLevelUrgent',
    };
    return ReportModel(
      id: map['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? ''),
      userId: map['usuario']?.toString() ?? '',
      anonymous: map['anonima'] as bool? ?? false,
      latitude: double.tryParse(map['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(map['longitude']?.toString() ?? '0') ?? 0.0,
      address: map['endereco'] as String?,
      description: map['descricao'] as String? ?? '',
      fireLevel: nivelMap[map['nivel_fogo']] ?? 'fireLevelSmall',
      smokeLevel: map['nivel_fumaca'] as String? ?? '',
      riskLevel: map['nivel_risco'] as String? ?? '',
      images: List<String>.from(map['imagens'] ?? []),
      localImages: const [],
      status: map['status'] as String? ?? 'pendente',
      offlineCreated: false,
      synced: true,
      observations: map['observacoes'] as String?,
      score: (map['score'] as num?)?.toInt(),
    );
  }

  // ── Serialização para Django ─────────────────────────────────────────────────

  /// Converte para Map no formato esperado pelo backend Django (snake_case).
  Map<String, dynamic> toDjangoMap() {
    const fireLevelMap = {
      'fireLevelSmall': 'baixo', 'fireLevelMedium': 'medio',
      'fireLevelNearHome': 'alto', 'fireLevelUrgent': 'critico',
    };
    return {
      'id': id,
      'anonima': anonymous,
      'latitude': latitude,
      'longitude': longitude,
      'endereco': address ?? '',
      'descricao': description,
      'nivel_fogo': fireLevelMap[fireLevel] ?? 'baixo',
      'nivel_fumaca': smokeLevel,
      'nivel_risco': riskLevel,
      'ha_fumaca': smokeLevel.isNotEmpty,
      'proximo_residencia': riskLevel == 'fireLevelNearHome',
      'imagens': images,
      'status': status,
    };
  }

  // ── Serialização ────────────────────────────────────────────────────────────

  /// Converte para Map para gravação no Firestore ou Hive.
  ///
  /// Nota: datas são salvas como strings ISO 8601 (não Timestamp)
  /// para compatibilidade com o cache local do Hive.
  /// O Firestore aceita strings ISO — o fromMap faz a conversão de volta.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'anonymous': anonymous,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'fireLevel': fireLevel,
      'smokeLevel': smokeLevel,
      'riskLevel': riskLevel,
      'images': images,
      'localImages': localImages,
      'status': status,
      'offlineCreated': offlineCreated,
      'synced': synced,
      'observations': observations,
      'respondedBy': respondedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'score': score,
    };
  }

  // ── Cópia com modificações ──────────────────────────────────────────────────

  /// Retorna uma cópia com os campos fornecidos substituídos.
  /// Necessário pois a entidade é imutável (todos campos são `final`).
  ReportModel copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    bool? anonymous,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? fireLevel,
    String? smokeLevel,
    String? riskLevel,
    List<String>? images,
    List<String>? localImages,
    String? status,
    bool? offlineCreated,
    bool? synced,
    DateTime? updatedAt,
    String? observations,
    String? respondedBy,
    int? score,
  }) {
    return ReportModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      anonymous: anonymous ?? this.anonymous,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      fireLevel: fireLevel ?? this.fireLevel,
      smokeLevel: smokeLevel ?? this.smokeLevel,
      riskLevel: riskLevel ?? this.riskLevel,
      images: images ?? this.images,
      localImages: localImages ?? this.localImages,
      status: status ?? this.status,
      offlineCreated: offlineCreated ?? this.offlineCreated,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
      observations: observations ?? this.observations,
      respondedBy: respondedBy ?? this.respondedBy,
      score: score ?? this.score,
    );
  }
}
