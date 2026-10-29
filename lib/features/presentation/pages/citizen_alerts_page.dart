import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api/websocket_service.dart';
import '../../../services/local/hive_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Alertas regionais recebidos via WebSocket + cache Hive.
///
/// Ao iniciar, carrega o histórico salvo localmente.
/// Escuta [WebSocketService.onNewAlert] e persiste cada alerta no Hive.
final citizenAlertsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final cached = _loadAlerts();
  yield cached;

  await for (final alert in WebSocketService.onNewAlert) {
    final entry = {
      'title': alert['title'] as String? ?? 'Alerta regional',
      'message': alert['message'] as String? ?? '',
      'type': alert['type'] as String? ?? 'info',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };
    _saveAlert(entry);
    yield _loadAlerts();
  }
});

List<Map<String, dynamic>> _loadAlerts() {
  final raw = HiveService.getSetting('citizen_alerts');
  if (raw is List) {
    return List<Map<String, dynamic>>.from(
        raw.map((e) => Map<String, dynamic>.from(e as Map)));
  }
  return [];
}

void _saveAlert(Map<String, dynamic> alert) {
  final existing = _loadAlerts();
  existing.insert(0, alert);
  HiveService.saveSetting('citizen_alerts', existing.take(100).toList());
}

// ── Página ────────────────────────────────────────────────────────────────────

/// Tela de alertas regionais para cidadãos.
///
/// Lista alertas emitidos pelas autoridades via WebSocket (novo_alerta).
/// Persiste localmente para histórico. Diferencia tipos: crítico / alto / info.
class CitizenAlertsPage extends ConsumerWidget {
  const CitizenAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(citizenAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Alertas Regionais'),
            SizedBox(width: 8),
            _LiveDot(),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpar histórico',
            onPressed: () {
              HiveService.saveSetting('citizen_alerts', []);
            },
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

// ── Live dot ──────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFE65100),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  Color get _borderColor {
    switch (alert['type'] as String? ?? '') {
      case 'critical':
        return const Color(0xFFE65100);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF0284C7);
    }
  }

  IconData get _icon {
    switch (alert['type'] as String? ?? '') {
      case 'critical':
        return Icons.local_fire_department;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = alert['title'] as String? ?? 'Alerta';
    final message = alert['message'] as String? ?? '';
    final ts = alert['createdAt'] as String?;
    String dateStr = '';
    if (ts != null) {
      try {
        dateStr = DateFormat('dd/MM HH:mm').format(DateTime.parse(ts));
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _borderColor, width: 4)),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _borderColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium),
                    ),
                  ],
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Nenhum alerta no momento.',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Alertas emitidos pelas autoridades\naparecerão aqui em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
