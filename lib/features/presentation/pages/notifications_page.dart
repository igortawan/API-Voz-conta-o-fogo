// ============================================================================
// notifications_page.dart
// ----------------------------------------------------------------------------
// Tela de notificações do cidadão — lista de atualizações das denúncias.
//
// Fluxo:
//   • As notificações são criadas no Firestore pelo FirestoreService quando
//     a autoridade atualiza o status de uma denúncia (updateReportStatus).
//   • O stream [_userNotificationsProvider] escuta em tempo real a coleção
//     'notifications' filtrada pelo uid do usuário logado.
//   • Ao tocar em uma notificação não lida, marca-a como lida individualmente.
//   • O botão "Marcar todas como lidas" chama markAllNotificationsRead (batch).
//
// Providers deste arquivo:
//   • [_userNotificationsProvider] — StreamProvider privado, escuta o Firestore
//   • [unreadCountProvider]        — Provider<AsyncValue<int>> PÚBLICO, exportado
//     para HomePage exibir o badge vermelho no sino de notificações.
//
// Cada notificação contém: title, message, newStatus, createdAt, read, docId.
// O campo 'docId' é injetado pelo FirestoreService ao mapear os documentos.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api/websocket_service.dart';
import '../../../services/local/hive_service.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Notificações de status recebidas via WebSocket (onReportUpdated).
/// Complementa o cache local de notificações salvas no Hive.
final _userNotificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final uid = ref.watch(authStateProvider)?.uid;
  if (uid == null) {
    yield [];
    return;
  }

  // Carga inicial do cache local
  final cached = _loadCachedNotifications();
  yield cached;

  // Escuta atualizações em tempo real via WebSocket
  await for (final report in WebSocketService.onReportUpdated) {
    if (report.userId == uid) {
      final notif = {
        'title': 'Denúncia atualizada',
        'message': 'Status: ${report.status}',
        'newStatus': report.status,
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
        'docId': report.id,
      };
      _cacheNotification(notif);
      yield _loadCachedNotifications();
    }
  }
});

List<Map<String, dynamic>> _loadCachedNotifications() {
  final raw = HiveService.getSetting('user_notifications');
  if (raw is List) return List<Map<String, dynamic>>.from(raw.map((e) => Map<String, dynamic>.from(e as Map)));
  return [];
}

void _cacheNotification(Map<String, dynamic> notif) {
  final existing = _loadCachedNotifications();
  existing.insert(0, notif);
  HiveService.saveSetting('user_notifications', existing.take(50).toList());
}

/// Contagem de notificações não lidas do usuário logado.
///
/// Provider PÚBLICO — exportado para HomePage exibir o badge no sino.
/// Derivado de [_userNotificationsProvider]: filtra notificações onde 'read' == false.
/// Retorna AsyncValue<int> para que a UI possa tratar os estados loading/error.
final unreadCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(_userNotificationsProvider).whenData(
        (list) => list.where((n) => n['read'] == false).length,
      );
});

// ── Página ────────────────────────────────────────────────────────────────────

/// Tela que lista as notificações do usuário sobre suas denúncias.
///
/// Exibida ao tocar no sino da HomePage. Acesso via Navigator.push.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(_userNotificationsProvider);
    final uid = ref.watch(authStateProvider)?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () {
                final notifs = _loadCachedNotifications()
                    .map((n) => {...n, 'read': true})
                    .toList();
                HiveService.saveSetting('user_notifications', notifs);
              },
              child: const Text('Marcar todas como lidas',
                  style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: notifAsync.when(
        // ── Lista de notificações ────────────────────────────────────────
        data: (notifications) {
          // Estado vazio: orienta o usuário sobre o propósito desta tela
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Nenhuma notificação ainda.',
                      style: TextStyle(color: AppColors.textLight)),
                  const SizedBox(height: 6),
                  const Text(
                    'Você será avisado quando sua denúncia\nfor atualizada pela autoridade.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          // Lista com separadores visuais entre itens
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = notifications[i];
              return _NotificationCard(
                notification: n,
                onTap: () async {
                  // Marca como lida ao tocar (somente se ainda não lida)
                  final docId = n['docId'] as String?;
                  if (docId != null && n['read'] == false) {
                    final notifs = _loadCachedNotifications()
                        .map((x) => x['docId'] == docId ? {...x, 'read': true} : x)
                        .toList();
                    HiveService.saveSetting('user_notifications', notifs);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

// ── Card de notificação ───────────────────────────────────────────────────────

/// Card visual para uma notificação individual.
///
/// Diferencia visualmente notificações lidas (fundo branco, texto normal)
/// de não lidas (fundo levemente verde, texto em negrito + ponto indicador).
/// O ícone e a cor do ícone refletem o status da denúncia atualizada.
class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] == true;
    final title = notification['title'] as String? ?? 'Atualização';
    final message = notification['message'] as String? ?? '';
    final newStatus = notification['newStatus'] as String? ?? '';

    final ts = notification['createdAt'];
    String dateStr = '';
    if (ts != null) {
      try {
        final date = DateTime.parse(ts as String);
        dateStr = DateFormat('dd/MM HH:mm').format(date);
      } catch (_) {}
    }

    final statusColor = _statusColor(newStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Não lida → leve destaque com borda e fundo levemente coloridos
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ícone do status ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon(newStatus), color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Conteúdo textual ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                // Não lida → negrito; lida → normal
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14)),
                      ),
                      // Ponto indicador de não lida
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(message,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium)),
                  // Timestamp (só exibe se disponível)
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna a cor correspondente ao status da denúncia atualizada.
  Color _statusColor(String s) {
    switch (s) {
      case AppConstants.statusAnalyzing:
        return Colors.purple;
      case AppConstants.statusAttended:
        return Colors.green;
      case AppConstants.statusRejected:
        return Colors.red;
      default:
        return AppColors.statusSent; // enviada / pendente → azul
    }
  }

  /// Retorna o ícone correspondente ao status da denúncia atualizada.
  IconData _statusIcon(String s) {
    switch (s) {
      case AppConstants.statusAnalyzing:
        return Icons.search;
      case AppConstants.statusAttended:
        return Icons.check_circle;
      case AppConstants.statusRejected:
        return Icons.cancel;
      default:
        return Icons.send; // enviada / pendente
    }
  }
}
