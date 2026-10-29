// ============================================================================
// report_controller.dart — migrado para Django API + WebSocket
// ============================================================================

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/report_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../../../services/api/django_report_service.dart';
import '../../../../services/api/websocket_service.dart';
import '../../../../services/cloudinary/storage_service.dart';
import '../../../../services/local/hive_service.dart';
import '../../../../services/local/sync_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

// ── Providers de leitura ─────────────────────────────────────────────────────

/// Stream de denúncias do usuário via Django API + WebSocket.
/// Busca inicial ao montar, re-busca a cada nova denúncia recebida via WS.
final userReportsProvider = StreamProvider<List<ReportModel>>((ref) async* {
  final authUser = ref.watch(authStateProvider);
  final uid = authUser?.uid;
  if (uid == null || (authUser?.isAnonymous ?? true)) {
    yield [];
    return;
  }

  // Carga inicial
  yield await DjangoReportService.getUserReports();

  // Re-emite sempre que o WebSocket notificar uma nova ocorrência/atualização
  await for (final _ in WebSocketService.onNewReport) {
    yield await DjangoReportService.getUserReports();
  }
});

/// Denúncias salvas localmente no Hive, filtradas pelo usuário atual.
/// Para usuários anônimos, usa o UID local único gerado no login anônimo.
final localReportsProvider = Provider<List<ReportModel>>((ref) {
  final authUser = ref.watch(authStateProvider);
  final uid = authUser?.uid;

  if (uid == null) return [];

  final all = HiveService.getAllReports().map(ReportModel.fromMap).toList();
  return all.where((r) => r.userId == uid).toList();
});

/// Controller principal de envio de denúncias.
final reportControllerProvider =
    StateNotifierProvider<ReportController, ReportState>((ref) {
  return ReportController(ref);
});

// ── Estado ────────────────────────────────────────────────────────────────────

class ReportState {
  final bool isLoading;
  final String? error;
  final bool success;
  final bool savedOffline;

  const ReportState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.savedOffline = false,
  });

  ReportState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool? savedOffline,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      savedOffline: savedOffline ?? this.savedOffline,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class ReportController extends StateNotifier<ReportState> {
  final Ref _ref;
  static const _uuid = Uuid();

  ReportController(this._ref) : super(const ReportState());

  // ── Envio de denúncia ───────────────────────────────────────────────────────

  Future<void> submitReport({
    required double latitude,
    required double longitude,
    String? address,
    required String description,
    required String fireLevel,
    required String smokeLevel,
    required String riskLevel,
    required bool anonymous,
    required List<File> images,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    final reportId = _uuid.v4();
    // Para usuários autenticados usa o ID do servidor; para anônimos usa o
    // UID local único (anon_<uuid>) que já está no authStateProvider.
    final serverUserId = await AuthApiService.userId;
    final realUserId =
        serverUserId ?? _ref.read(authStateProvider)?.uid ?? 'unknown';
    final now = DateTime.now();

    final report = ReportModel(
      id: reportId,
      createdAt: now,
      userId: realUserId,
      anonymous: anonymous,
      latitude: latitude,
      longitude: longitude,
      address: address,
      description: description,
      fireLevel: fireLevel,
      smokeLevel: smokeLevel,
      riskLevel: riskLevel,
      images: const [],
      localImages: images.map((f) => f.path).toList(),
      status: AppConstants.statusPending,
      offlineCreated: false,
      synced: false,
    );

    final isOnline = await ConnectivityService.isOnline();

    if (isOnline) {
      await _submitOnline(report, images);
    } else {
      await _saveOffline(report);
    }
  }

  // ── Envio online ────────────────────────────────────────────────────────────

  Future<void> _submitOnline(ReportModel report, List<File> images) async {
    try {
      // Upload de imagens ao Cloudinary
      final imageUrls = images.isNotEmpty
          ? await StorageService.uploadMultipleImages(images, report.id)
          : <String>[];

      // Versão para Hive: userId REAL
      final localReport = report.copyWith(
        images: imageUrls,
        localImages: [],
        synced: true,
        status: AppConstants.statusSent,
      );

      // Versão para Django: status deve ser 'pendente' (choice válido no servidor);
      // não envia userId real para denúncias anônimas nem sessões sem conta.
      final isAnonSession = report.userId.startsWith('anon_');
      final djangoReport = localReport.copyWith(
        userId: (report.anonymous || isAnonSession) ? '' : report.userId,
        status: AppConstants.statusPending,
      );

      // Envia ao Django — o servidor calcula score e notifica autoridades via FCM
      final created = await DjangoReportService.createReport(djangoReport);
      if (created == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Servidor retornou erro. Verifique sua conexão e tente novamente.',
        );
        return;
      }

      // Cache local com userId REAL
      await HiveService.saveReport(localReport.toMap());

      state = state.copyWith(isLoading: false, success: true, savedOffline: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao enviar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // ── Salvamento offline ──────────────────────────────────────────────────────

  Future<void> _saveOffline(ReportModel report) async {
    try {
      final offlineReport = report.copyWith(
        offlineCreated: true,
        synced: false,
        status: AppConstants.statusPending,
      );
      await HiveService.saveReport(offlineReport.toMap());
      await HiveService.addToPendingSync(report.id);
      state = state.copyWith(isLoading: false, success: true, savedOffline: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao salvar denúncia. Tente novamente.',
      );
    }
  }

  // ── Sincronização manual ────────────────────────────────────────────────────

  Future<void> syncPending() async {
    await SyncService.syncPendingReports();
  }

  void reset() {
    state = const ReportState();
  }
}
