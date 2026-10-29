// ============================================================================
// citizen_stats_page.dart
// ----------------------------------------------------------------------------
// Tela de estatísticas pessoais do cidadão.
//
// Exibe um resumo das denúncias do usuário logado:
//   • Totais por status (contadores coloridos)
//   • Barras de proporção visual (sem library externa)
//   • Atividade por dia — últimos 7 dias
//   • Indicador de taxa de resolução
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../report/data/models/report_model.dart';
import '../../report/presentation/controllers/report_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Tela de estatísticas pessoais do cidadão.
///
/// Combina denúncias do Firestore (online) e do Hive (offline) para
/// fornecer um resumo completo mesmo sem conexão.
class CitizenStatsPage extends ConsumerWidget {
  const CitizenStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnon = ref.watch(authStateProvider)?.isAnonymous ?? true;

    // Usa as denúncias já carregadas pelos providers existentes
    final localReports = ref.watch(localReportsProvider);
    final reportsAsync = isAnon ? null : ref.watch(userReportsProvider);

    // Combina local + Firestore (deduplicado por ID)
    final List<ReportModel> all;
    if (reportsAsync != null) {
      final firestore = reportsAsync.valueOrNull ?? [];
      final firestoreIds = firestore.map((r) => r.id).toSet();
      final onlyLocal = localReports.where((r) => !firestoreIds.contains(r.id)).toList();
      all = [...onlyLocal, ...firestore];
    } else {
      all = localReports;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Minhas Estatísticas'),
      ),
      body: all.isEmpty
          ? const _EmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalCard(reports: all),
                  const SizedBox(height: 20),
                  _StatusDistribution(reports: all),
                  const SizedBox(height: 20),
                  _FireLevelDistribution(reports: all),
                  const SizedBox(height: 20),
                  _ActivityChart(reports: all),
                  const SizedBox(height: 20),
                  _ResolutionRate(reports: all),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Card totalizador ──────────────────────────────────────────────────────────

/// Linha com 4 contadores grandes: Total, Pendentes, Em Análise, Atendidas.
class _TotalCard extends StatelessWidget {
  final List<ReportModel> reports;
  const _TotalCard({required this.reports});

  @override
  Widget build(BuildContext context) {
    final pending = reports
        .where((r) =>
            r.status == AppConstants.statusPending ||
            r.status == AppConstants.statusSent)
        .length;
    final analyzing =
        reports.where((r) => r.status == AppConstants.statusAnalyzing).length;
    final attended =
        reports.where((r) => r.status == AppConstants.statusAttended).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          _BigStat(reports.length, 'Total', AppColors.primary),
          _BigStat(pending, 'Pendentes', AppColors.statusPending),
          _BigStat(analyzing, 'Em Análise', AppColors.statusAnalyzing),
          _BigStat(attended, 'Atendidas', AppColors.statusAttended),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _BigStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      );
}

// ── Distribuição por status ───────────────────────────────────────────────────

/// Barras de proporção para cada status.
class _StatusDistribution extends StatelessWidget {
  final List<ReportModel> reports;
  const _StatusDistribution({required this.reports});

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final items = [
      (AppConstants.statusPending,   'Pendente',   AppColors.statusPending),
      (AppConstants.statusSent,      'Enviada',    AppColors.statusSent),
      (AppConstants.statusAnalyzing, 'Em Análise', AppColors.statusAnalyzing),
      (AppConstants.statusAttended,  'Atendida',   AppColors.statusAttended),
      (AppConstants.statusRejected,  'Rejeitada',  AppColors.statusRejected),
    ];

    return _Section(
      title: 'Distribuição por Status',
      child: Column(
        children: items.map((item) {
          final count = reports.where((r) => r.status == item.$1).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProportionBar(
              label: item.$2,
              count: count,
              total: total,
              color: item.$3,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Distribuição por tipo de fogo ─────────────────────────────────────────────

/// Barras de proporção para cada nível de fogo reportado.
class _FireLevelDistribution extends StatelessWidget {
  final List<ReportModel> reports;
  const _FireLevelDistribution({required this.reports});

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final levels = [
      (AppConstants.fireLevelSmall,    'Foco Pequeno',           Colors.green),
      (AppConstants.fireLevelMedium,   'Incêndio Florestal',     AppColors.statusSent),
      (AppConstants.fireLevelNearHome, 'Perto de Residência',    AppColors.warning),
      (AppConstants.fireLevelUrgent,   'Urgente',                AppColors.emergency),
    ];

    return _Section(
      title: 'Tipo de Ocorrência Reportada',
      child: Column(
        children: levels.map((item) {
          final count = reports.where((r) => r.fireLevel == item.$1).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProportionBar(
              label: item.$2,
              count: count,
              total: total,
              color: item.$3,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Atividade por dia (últimos 7 dias) ────────────────────────────────────────

/// Mini gráfico de barras mostrando denúncias por dia nos últimos 7 dias.
class _ActivityChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ActivityChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Monta lista de (dia, contagem) para os últimos 7 dias
    final days = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = reports.where((r) {
        return r.createdAt.year == day.year &&
            r.createdAt.month == day.month &&
            r.createdAt.day == day.day;
      }).length;
      return (day, count);
    });

    final maxCount = days.map((d) => d.$2).fold(0, (a, b) => a > b ? a : b);

    return _Section(
      title: 'Atividade — Últimos 7 dias',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((entry) {
          final day = entry.$1;
          final count = entry.$2;
          final barFraction = maxCount == 0 ? 0.0 : count / maxCount;
          final isToday = day.day == today.day &&
              day.month == today.month &&
              day.year == today.year;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  // Contagem acima da barra
                  Text(
                    count > 0 ? '$count' : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barra proporcional (altura mínima de 4px para visibilidade)
                  Container(
                    height: 60 * barFraction + (count > 0 ? 4 : 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label do dia (seg, ter, qua...)
                  Text(
                    DateFormat('E', 'pt_BR').format(day),
                    style: TextStyle(
                      fontSize: 9,
                      color: isToday ? AppColors.primary : AppColors.textLight,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Taxa de resolução ─────────────────────────────────────────────────────────

/// Card com percentual de denúncias que foram atendidas.
class _ResolutionRate extends StatelessWidget {
  final List<ReportModel> reports;
  const _ResolutionRate({required this.reports});

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final attended =
        reports.where((r) => r.status == AppConstants.statusAttended).length;
    final rate = total == 0 ? 0.0 : attended / total;
    final pct = (rate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Anel circular representando o percentual
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate >= 0.7
                        ? AppColors.statusAttended
                        : rate >= 0.4
                            ? AppColors.warning
                            : AppColors.emergency,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Taxa de Resolução',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '$attended de $total denúncia(s) foram atendidas pelas autoridades.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Card seção com título e conteúdo encapsulado.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

/// Linha de barra de proporção: label + barra preenchida + contagem.
class _ProportionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ProportionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vazio — sem denúncias ainda.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma denúncia registrada ainda.',
              style: TextStyle(color: AppColors.textLight, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Faça sua primeira denúncia para ver as estatísticas aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      );
}
