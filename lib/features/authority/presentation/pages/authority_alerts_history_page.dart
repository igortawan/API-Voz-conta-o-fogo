import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api/django_report_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final _alertsHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authStateProvider);
  return DjangoReportService.getAlerts();
});

class AuthorityAlertsHistoryPage extends ConsumerWidget {
  const AuthorityAlertsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_alertsHistoryProvider);
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 14),
                const Text(
                  'Nenhum alerta emitido ainda.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(_alertsHistoryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_alertsHistoryProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AlertHistoryCard(alert: alerts[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            const Text('Erro ao carregar alertas', style: TextStyle(color: AppColors.textMedium)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.invalidate(_alertsHistoryProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertHistoryCard({required this.alert});

  static const _nivelConfig = {
    'baixo':   (Colors.green,                'Baixo'),
    'medio':   (AppColors.warning,           'Médio'),
    'alto':    (AppColors.statusSent,        'Alto'),
    'critico': (AppColors.emergency,         'Crítico'),
  };

  @override
  Widget build(BuildContext context) {
    final nivel = alert['nivel_risco'] as String? ?? 'medio';
    final cfg   = _nivelConfig[nivel] ?? (AppColors.textLight, nivel);
    final color = cfg.$1 as Color;
    final label = cfg.$2 as String;
    final vigente = alert['vigente'] as bool? ?? false;

    DateTime? createdAt;
    final raw = alert['created_at'];
    if (raw is String) createdAt = DateTime.tryParse(raw);
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yy HH:mm').format(createdAt.toLocal())
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: nível + data
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                const Spacer(),
                if (!vigente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Encerrado', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 10),
            // Título
            Text(
              alert['titulo'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            // Descrição
            if ((alert['descricao'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                alert['descricao'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
