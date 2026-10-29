// ============================================================================
// api_service.dart
// ----------------------------------------------------------------------------
// Cliente HTTP para a SemiáridoFogo API (FastAPI — http://10.0.2.2:8000).
//
// Responsabilidades:
//   • Autenticação: login/registro via JWT, ponteando Firebase UID → senha bridge
//   • Sincronização de usuário após login Firebase
//   • POST de ocorrência quando o cidadão envia uma denúncia
//   • Score de prioridade (0–100) por ID de ocorrência
//   • Detecção de duplicata antes do envio
//
// Design:
//   • Todos os métodos são estáticos (singleton de estado em variáveis de classe)
//   • Nenhum método lança exceção para fora — falhas silenciosas para nunca
//     quebrar o fluxo principal do Firebase
//   • JWT armazenado em memória (perdido ao reiniciar o app, re-autenticado
//     no próximo login Firebase)
//   • _reportIdMap associa IDs Firebase (String UUID) → IDs da API (int)
//     para buscar o score de prioridade de uma denúncia já enviada
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/report/data/models/report_model.dart';
import '../../core/constants/app_constants.dart';

// ── DTOs de resposta ──────────────────────────────────────────────────────────

/// Score de prioridade retornado pelo endpoint
/// GET /api/v1/ocorrencias/{id}/score-prioridade
class ScoreData {
  final double score;
  final String nivelCalculado;
  final String recomendacao;

  const ScoreData({
    required this.score,
    required this.nivelCalculado,
    required this.recomendacao,
  });
}

/// Resultado de detecção de duplicata retornado pelo endpoint
/// POST /api/v1/verificacoes/detectar-duplicata
class DuplicataResult {
  final bool isDuplicate;
  final double confianca;

  const DuplicataResult({required this.isDuplicate, required this.confianca});
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class ApiService {
  // URL base: 10.0.2.2 é o alias do localhost do host no emulador Android
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  static String? _token;

  // Mapa de Firebase report UUID → ID inteiro na API
  // Populado quando postOcorrencia() recebe 201 com sucesso
  static final Map<String, int> _reportIdMap = {};

  // ── Headers ────────────────────────────────────────────────────────────────

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Senha bridge ───────────────────────────────────────────────────────────

  // Senha determinística derivada do UID do Firebase.
  // Nunca requer input do usuário — transparente para o cidadão.
  static String _bridgePassword(String uid) {
    final suffix = uid.length >= 8 ? uid.substring(0, 8) : uid;
    return 'vcf_$suffix';
  }

  // ── Mapeamento de campos Firebase → API ────────────────────────────────────

  static String _mapFireLevel(String fireLevel) {
    switch (fireLevel) {
      case AppConstants.fireLevelSmall:
        return 'baixo';
      case AppConstants.fireLevelMedium:
        return 'medio';
      case AppConstants.fireLevelNearHome:
        return 'alto';
      case AppConstants.fireLevelUrgent:
        return 'critico';
      default:
        return 'baixo';
    }
  }

  // ── API pública ────────────────────────────────────────────────────────────

  /// Sincroniza o usuário com a API após login/registro no Firebase.
  ///
  /// Fluxo: tenta login → se falhar (401) → registra → tenta login novamente.
  /// Em qualquer erro de rede ou resposta inesperada, retorna silenciosamente.
  static Future<void> syncUserWithApi(
    String email,
    String firebaseUid, {
    String role = 'cidadao',
    String? displayName,
  }) async {
    try {
      final password = _bridgePassword(firebaseUid);
      final loggedIn = await _login(email, password);
      if (loggedIn) return;

      // 401 → usuário não existe ainda → registra
      final apiRole = role == AppConstants.roleAuthority ? 'autoridade' : 'cidadao';
      final name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Usuário VCF';
      await _register(email, password, name, apiRole);
      await _login(email, password);
    } catch (_) {
      // Rede indisponível ou API fora do ar — sem impacto no app
    }
  }

  /// Envia uma ocorrência para a API após salvar no Firestore.
  ///
  /// Se a chamada tiver sucesso (201), armazena o ID inteiro retornado
  /// em [_reportIdMap] associado ao UUID do Firebase. Esse ID é necessário
  /// para buscar o score de prioridade via [getScorePrioridade].
  static Future<void> postOcorrencia(ReportModel report) async {
    if (_token == null) return;
    try {
      final descLen = report.description.length.clamp(0, 50) as int;
      final titulo =
          '${report.fireLevel} — ${report.description.substring(0, descLen)}';

      final body = {
        'titulo': titulo,
        'descricao': report.description,
        'latitude': report.latitude,
        'longitude': report.longitude,
        'nivel_urgencia': _mapFireLevel(report.fireLevel),
        'ha_fumaca': report.smokeLevel != AppConstants.smokeLevelLight,
        'proximo_residencia': report.riskLevel == AppConstants.fireLevelNearHome,
        'municipio': 'Paulistana',
      };

      final resp = await http
          .post(
            Uri.parse('$_baseUrl/ocorrencias'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 201) {
        final apiId = jsonDecode(resp.body)['id'] as int?;
        if (apiId != null) _reportIdMap[report.id] = apiId;
      }
    } catch (_) {}
  }

  /// Busca o score de prioridade (0–100) de uma denúncia já enviada à API.
  ///
  /// Recebe o UUID do Firebase e usa [_reportIdMap] para converter para o
  /// ID inteiro da API. Retorna null se o ID não estiver mapeado (denúncia
  /// offline, enviada em sessão anterior, ou API indisponível).
  static Future<ScoreData?> getScorePrioridade(String firebaseReportId) async {
    if (_token == null) return null;
    final apiId = _reportIdMap[firebaseReportId];
    if (apiId == null) return null;
    try {
      final resp = await http
          .get(
            Uri.parse('$_baseUrl/ocorrencias/$apiId/score-prioridade'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return ScoreData(
          score: (data['score'] as num).toDouble(),
          nivelCalculado: data['nivel_calculado'] as String? ?? '',
          recomendacao: data['recomendacao'] as String? ?? '',
        );
      }
    } catch (_) {}
    return null;
  }

  /// Verifica se uma nova denúncia é duplicata de outra já registrada.
  ///
  /// Usa a fórmula de Haversine (distância geográfica) + índice de Jaccard
  /// (similaridade de título) para calcular a confiança de duplicidade.
  /// Retorna null se a API estiver indisponível.
  static Future<DuplicataResult?> detectarDuplicata(
    double lat,
    double lng,
    String titulo,
  ) async {
    if (_token == null) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/verificacoes/detectar-duplicata'),
            headers: _headers,
            body: jsonEncode({
              'latitude': lat,
              'longitude': lng,
              'titulo': titulo,
              'raio_metros': 500,
              'janela_horas': 24,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return DuplicataResult(
          isDuplicate: data['e_duplicata'] as bool? ?? false,
          confianca: (data['confianca'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (_) {}
    return null;
  }

  // ── Métodos privados ───────────────────────────────────────────────────────

  static Future<bool> _login(String email, String password) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        _token = jsonDecode(resp.body)['access_token'] as String?;
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _register(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/usuarios'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': name,
              'email': email,
              'senha': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
