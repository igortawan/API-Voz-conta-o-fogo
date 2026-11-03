import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../features/report/data/models/report_model.dart';
import 'auth_api_service.dart';

/// Serviço de denúncias via API Django — substitui FirestoreService para reports.
class DjangoReportService {
  static const _base = AppConstants.apiBaseUrl;

  // ── Lista denúncias do usuário ───────────────────────────────────────────────

  static Future<List<ReportModel>> getUserReports() async {
    final headers = await AuthApiService.authHeaders;
    final res = await http.get(
      Uri.parse('$_base/ocorrencias/'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Erro ${res.statusCode} ao carregar denúncias');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is Map ? (decoded['results'] as List? ?? []) : decoded as List;
    return data.map((m) => ReportModel.fromDjangoMap(m as Map<String, dynamic>)).toList();
  }

  // ── Cria denúncia ────────────────────────────────────────────────────────────

  static Future<ReportModel?> createReport(ReportModel report) async {
    try {
      final headers = await AuthApiService.authHeaders;
      final res = await http.post(
        Uri.parse('$_base/ocorrencias/'),
        headers: headers,
        body: jsonEncode(report.toDjangoMap()),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 201) return null;
      return ReportModel.fromDjangoMap(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Score de prioridade ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getScore(String reportId) async {
    try {
      final headers = await AuthApiService.authHeaders;
      final res = await http.get(
        Uri.parse('$_base/ocorrencias/$reportId/score/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Detecção de duplicatas ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> detectDuplicate({
    required double lat,
    required double lng,
    required String titulo,
  }) async {
    try {
      final headers = await AuthApiService.authHeaders;
      final res = await http.post(
        Uri.parse('$_base/ocorrencias/detectar-duplicata/'),
        headers: headers,
        body: jsonEncode({'latitude': lat, 'longitude': lng, 'titulo': titulo}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Atualiza status da denúncia (autoridade) ────────────────────────────────

  static Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? observations,
    String? respondedBy,
  }) async {
    try {
      final headers = await AuthApiService.authHeaders;
      final res = await http.patch(
        Uri.parse('$_base/ocorrencias/$reportId/'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          if (observations != null) 'observacoes': observations,
          if (respondedBy != null) 'respondido_por': respondedBy,
        }),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Cria alerta para todos os usuários (autoridade) ────────────────────────

  static Future<bool> createAlert({
    required String titulo,
    required String descricao,
    required String nivelRisco,
  }) async {
    try {
      final headers = await AuthApiService.authHeaders;
      final res = await http.post(
        Uri.parse('$_base/alertas/'),
        headers: headers,
        body: jsonEncode({'titulo': titulo, 'descricao': descricao, 'nivel_risco': nivelRisco}),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Lista alertas emitidos (autoridade vê todos; demais veem apenas vigentes) ─

  static Future<List<Map<String, dynamic>>> getAlerts() async {
    final headers = await AuthApiService.authHeaders;
    final res = await http.get(
      Uri.parse('$_base/alertas/'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Erro ${res.statusCode} ao carregar alertas');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is Map ? (decoded['results'] as List? ?? []) : decoded as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ── Upload de imagem via Cloudinary (inalterado) ────────────────────────────

  static Future<List<String>> uploadImages(List<File> images, String reportId) async {
    // Cloudinary continua sendo usado diretamente no Flutter
    // via StorageService — não passa pela API Django
    return [];
  }
}
