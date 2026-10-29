// ============================================================================
// sync_service.dart
// ----------------------------------------------------------------------------
// Serviço de sincronização de denúncias criadas offline.
//
// Quando o dispositivo está sem internet, as denúncias são salvas no Hive
// (armazenamento local) com `synced: false`. Assim que a conexão retorna,
// este serviço processa a fila de pendentes e envia ao Firestore.
//
// Chamado em dois contextos:
//   1. Pelo WorkManager em background (a cada 15 minutos) via callbackDispatcher
//      em main.dart — funciona mesmo com o app fechado.
//   2. Manualmente pelo [ReportController.syncPending()] quando o usuário
//      abre a tela de "Minhas Denúncias" ou ao retornar a conectividade.
//
// Fluxo de cada report pendente:
//   1. Carrega imagens locais e faz upload ao Cloudinary
//   2. Envia o report completo (com URLs) ao Firestore via [FirestoreService]
//   3. Marca como sincronizado no Hive
//   4. Remove da fila pendingSyncBox
// ============================================================================

import 'dart:io';
import '../api/django_report_service.dart';
import '../cloudinary/storage_service.dart';
import '../../features/report/data/models/report_model.dart';
import 'hive_service.dart';

class SyncService {
  /// Processa todos os reports pendentes da fila local.
  ///
  /// Falhas individuais são silenciadas — o report permanece na fila para
  /// a próxima tentativa. Isso garante que um erro de rede em um item
  /// não bloqueie a sincronização dos demais.
  static Future<void> syncPendingReports() async {
    final pending = HiveService.getPendingReports();

    for (final report in pending) {
      try {
        await _syncReport(report);
      } catch (_) {
        // Ignora o erro e continua com o próximo.
        // O report permanece na pendingSyncBox e será retentado no próximo ciclo.
      }
    }
  }

  /// Sincroniza um único report: faz upload das imagens locais e envia ao Firestore.
  static Future<void> _syncReport(Map<String, dynamic> report) async {
    final id = report['id'] as String;

    // ── 1. Upload das imagens locais ao Cloudinary ────────────────────────────
    final localImages = List<String>.from(report['localImages'] ?? []);
    final uploadedUrls = <String>[];

    for (final localPath in localImages) {
      final file = File(localPath);
      if (file.existsSync()) {
        // Faz upload individual — usa retry automático do http se necessário
        final url = await StorageService.uploadReportImage(file, id);
        uploadedUrls.add(url);
      }
      // Se o arquivo local não existir mais, ignora (pode ter sido apagado pelo SO)
    }

    // ── 2. Mescla URLs já existentes (se houver) com as recém-enviadas ────────
    final existingUrls = List<String>.from(report['images'] ?? []);
    final allImageUrls = [...existingUrls, ...uploadedUrls];

    // ── 3. Prepara o payload final sem paths locais ───────────────────────────
    final payload = Map<String, dynamic>.from(report);
    payload.remove('localImages'); // remove paths do dispositivo — não armazenar no Firestore
    payload['images'] = allImageUrls;
    payload['synced'] = true;
    payload['offlineCreated'] = report['offlineCreated'] ?? true;

    // ── 4. PRIVACIDADE: anonimiza o userId antes de enviar ao Firestore ───────
    // O Hive sempre armazena o UID real (para filtro local correto).
    // No Firestore, se o usuário marcou a denúncia como anônima, substituímos
    // o userId por 'anonymous' para preservar a privacidade no banco remoto.
    final isAnonymous = payload['anonymous'] as bool? ?? false;
    if (isAnonymous) {
      payload['userId'] = 'anonymous';
    }

    // ── 5. Envia ao Django ────────────────────────────────────────────────────
    final reportModel = ReportModel.fromMap(payload);
    await DjangoReportService.createReport(reportModel);

    // ── 6. Atualiza o cache local e remove da fila ────────────────────────────
    await HiveService.markReportAsSynced(id);
    await HiveService.removeFromPendingSync(id);
  }
}
