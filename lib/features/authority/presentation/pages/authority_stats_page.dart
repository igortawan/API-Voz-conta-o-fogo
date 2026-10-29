// ============================================================================
// authority_stats_page.dart
// ----------------------------------------------------------------------------
// Aba de estatísticas do painel da autoridade.
//
// Recebe a lista completa de [ReportModel] já carregada pelo AuthorityPage
// e computa métricas sem precisar de um novo listener Firestore.
//
// Seções exibidas:
//   1. Resumo geral — totais por status em cards grandes
//   2. Distribuição por tipo de fogo — barras de proporção
//   3. Atividade diária — mini gráfico de barras dos últimos 14 dias
//   4. Tempo médio de resposta — do statusSent ao primeiro statusAnalyzing
//   5. Focos por urgência — ranking visual dos tipos mais reportados
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../report/data/models/report_model.dart';

/// Aba de estatísticas do painel da autoridade.
///
/// Parâmetro: [reports] — lista completa passada pelo [AuthorityPage].
class AuthorityStatsPage extends StatelessWidget {
  final List<ReportModel> reports;
  const AuthorityStatsPage({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 72, color: Color(0xFFCCCCCC)),
            SizedBox(height: 16),
            Text(
              'Nenhuma denúncia registrada ainda.',
              style: TextStyle(color: AppColors.textLight, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(reports: reports),
          const SizedBox(height: 16),
          _StatusDistribution(reports: reports),
          const SizedBox(height: 16),
          _FireLevelDistribution(reports: reports),
          const SizedBox(height: 16),
          _DailyActivityChart(reports: reports),
          const SizedBox(height: 16),
          _ResponseTimeCard(reports: reports),
          const SizedBox(height: 16),
          _UrgencyRanking(reports: reports),
        ],
      ),
    );
  }
}

// ── 1. Resumo geral ───────────────────────────────────────────────────────────

/// Linha de 4 cards numerados com os totais por grupo de status.
class _SummaryRow extends StatelessWidget {
  final List<ReportModel> reports;
  const _SummaryRow({required this.reports});

  @override
  Widget build(BuildContext context) {
    final urgent = reports
        .where((r) => r.fireLevel == AppConstants.fireLevelUrgent)
        .length;
    final active = reports
        .where((r) =>
            r.status == AppConstants.statusPending ||
            r.status == AppConstants.statusSent ||
            r.status == AppConstants.statusAnalyzing)
        .length;
    final attended =
        reports.where((r) => r.status == AppConstants.statusAttended).length;
    final rejected =
        reports.where((r) => r.status == AppConstants.statusRejected).length;

    return Row(
      children: [
        _StatTile(reports.length, 'Total',    AppColors.primary),
        const SizedBox(width: 10),
        _StatTile(urgent,         'Urgentes', AppColors.emergency),
        const SizedBox(width: 10),
        _StatTile(active,         'Ativas',   AppColors.statusAnalyzing),
        const SizedBox(width: 10),
        _StatTile(attended,       'Atendidas', AppColors.statusAttended),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatTile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── 2. Distribuição por status ────────────────────────────────────────────────

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

    return _Card(
      title: 'Distribuição por Status',
      child: Column(
        children: items.map((item) {
          final count = reports.where((r) => r.status == item.$1).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PropBar(label: item.$2, count: count, total: total, color: item.$3),
          );
        }).toList(),
      ),
    );
  }
}

// ── 3. Distribuição por tipo de fogo ─────────────────────────────────────────

class _FireLevelDistribution extends StatelessWidget {
  final List<ReportModel> reports;
  const _FireLevelDistribution({required this.reports});

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final levels = [
      (AppConstants.fireLevelSmall,    'Foco Pequeno',         Colors.green),
      (AppConstants.fireLevelMedium,   'Incêndio Florestal',   AppColors.statusSent),
      (AppConstants.fireLevelNearHome, 'Perto de Residência',  AppColors.warning),
      (AppConstants.fireLevelUrgent,   'Urgente',              AppColors.emergency),
    ];

    return _Card(
      title: 'Tipo de Ocorrência',
      child: Column(
        children: levels.map((item) {
          final count = reports.where((r) => r.fireLevel == item.$1).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PropBar(label: item.$2, count: count, total: total, color: item.$3),
          );
        }).toList(),
      ),
    );
  }
}

// ── 4. Atividade diária — últimos 14 dias ────────────────────────────────────

/// Mini gráfico de barras mostrando denúncias por dia nos últimos 14 dias.
class _DailyActivityChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _DailyActivityChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) {
      final day = today.subtract(Duration(days: 13 - i));
      final count = reports.where((r) {
        return r.createdAt.year == day.year &&
            r.createdAt.month == day.month &&
            r.createdAt.day == day.day;
      }).length;
      return (day, count);
    });

    final maxCount =
        days.map((d) => d.$2).fold(0, (a, b) => a > b ? a : b);

    return _Card(
      title: 'Denúncias por Dia — Últimos 14 dias',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((entry) {
                final day = entry.$1;
                final count = entry.$2;
                final frac = maxCount == 0 ? 0.0 : count / maxCount;
                final isToday = day.day == today.day &&
                    day.month == today.month;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message:
                          '${DateFormat('dd/MM').format(day)}: $count denúncia(s)',
                      child: Container(
                        height: 70 * frac + (count > 0 ? 6 : 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Labels de datas (a cada 7 dias)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM').format(days.first.$1),
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
              Text(
                'Hoje',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 5. Tempo médio de resposta ────────────────────────────────────────────────

/// Calcula a diferença entre createdAt e updatedAt para denúncias atendidas.
class _ResponseTimeCard extends StatelessWidget {
  final List<ReportModel> reports;
  const _ResponseTimeCard({required this.reports});

  @override
  Widget build(BuildContext context) {
    final resolved = reports
        .where((r) =>
            r.status == AppConstants.statusAttended && r.updatedAt != null)
        .toList();

    String avgText;
    Color avgColor;

    if (resolved.isEmpty) {
      avgText = 'Sem dados';
      avgColor = AppColors.textLight;
    } else {
      final totalHours = resolved
          .map((r) => r.updatedAt!.difference(r.createdAt).inHours)
          .fold(0, (a, b) => a + b);
      final avgHours = totalHours / resolved.length;
      if (avgHours < 24) {
        avgText = '${avgHours.toStringAsFixed(0)}h';
        avgColor = AppColors.statusAttended;
      } else {
        final days = (avgHours / 24).toStringAsFixed(1);
        avgText = '${days}d';
        avgColor = avgHours < 72 ? AppColors.warning : AppColors.emergency;
      }
    }

    return _Card(
      title: 'Tempo Médio de Resposta',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: avgColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_outlined, color: avgColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avgText,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: avgColor,
                ),
              ),
              Text(
                'da criação até ser atendida\n(baseado em ${resolved.length} denúncia(s))',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 6. Ranking por urgência ───────────────────────────────────────────────────

/// Lista ordenada dos tipos de fogo mais reportados.
class _UrgencyRanking extends StatelessWidget {
  final List<ReportModel> reports;
  const _UrgencyRanking({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.fireLevel] = (counts[r.fireLevel] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      title: 'Ranking de Tipos Reportados',
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final name = entry.value.key;
          final count = entry.value.value;
          final isUrgent = name == AppConstants.fireLevelUrgent;
          final color = isUrgent ? AppColors.emergency : AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Número do ranking
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rank == 1 ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? color : AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // Contagem
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
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

class _PropBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _PropBar({
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
          width: 88,
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
