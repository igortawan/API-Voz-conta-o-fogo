import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../report/data/models/report_model.dart';

/// Tela de timeline de status de uma denúncia.
///
/// Exibe a progressão de status da denúncia (enviada → em análise → atendida)
/// como uma linha do tempo vertical com horários e observações da autoridade.
/// Atualiza em tempo real via WebSocket quando a denúncia sofre mudança de status.
class ReportTimelinePage extends StatelessWidget {
  final ReportModel report;

  const ReportTimelinePage({super.key, required this.report});

  static const _steps = [
    AppConstants.statusSent,
    AppConstants.statusAnalyzing,
    AppConstants.statusAttended,
  ];

  static const _stepLabels = {
    AppConstants.statusSent: 'Enviada',
    AppConstants.statusAnalyzing: 'Em análise',
    AppConstants.statusAttended: 'Atendida',
    AppConstants.statusPending: 'Pendente (offline)',
    AppConstants.statusRejected: 'Rejeitada',
  };

  static const _stepIcons = {
    AppConstants.statusSent: Icons.send,
    AppConstants.statusAnalyzing: Icons.search,
    AppConstants.statusAttended: Icons.check_circle,
    AppConstants.statusPending: Icons.cloud_off,
    AppConstants.statusRejected: Icons.cancel,
  };

  int _statusIndex(String status) {
    switch (status) {
      case AppConstants.statusSent:
        return 0;
      case AppConstants.statusAnalyzing:
        return 1;
      case AppConstants.statusAttended:
      case AppConstants.statusRejected:
        return 2;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final currentIdx = _statusIndex(report.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Histórico da Denúncia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ─────────────────────────────────────────────
            _HeaderCard(report: report),
            const SizedBox(height: 24),

            const Text(
              'LINHA DO TEMPO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),

            // ── Timeline de steps ──────────────────────────────────────
            ..._steps.asMap().entries.map((entry) {
              final i = entry.key;
              final stepStatus = entry.value;
              final isDone = i <= currentIdx;
              final isCurrent = i == currentIdx;
              final isLast = i == _steps.length - 1;

              return _TimelineStep(
                label: _stepLabels[stepStatus] ?? stepStatus,
                icon: _stepIcons[stepStatus] ?? Icons.circle,
                isDone: isDone,
                isCurrent: isCurrent,
                isLast: isLast,
                timestamp: isDone
                    ? (i == 0
                        ? fmt.format(report.createdAt)
                        : (report.updatedAt != null && isCurrent)
                            ? fmt.format(report.updatedAt!)
                            : null)
                    : null,
                note: isCurrent && report.observations != null
                    ? report.observations
                    : null,
                respondedBy: isCurrent ? report.respondedBy : null,
              );
            }),

            // ── Status especial: rejeitada ─────────────────────────────
            if (report.status == AppConstants.statusRejected)
              _TimelineStep(
                label: _stepLabels[AppConstants.statusRejected]!,
                icon: _stepIcons[AppConstants.statusRejected]!,
                isDone: true,
                isCurrent: true,
                isLast: true,
                timestamp: report.updatedAt != null
                    ? fmt.format(report.updatedAt!)
                    : null,
                note: report.observations,
                respondedBy: report.respondedBy,
                isRejected: true,
              ),

            const SizedBox(height: 24),

            // ── Score ──────────────────────────────────────────────────
            if (report.score != null) _ScoreCard(score: report.score!),
          ],
        ),
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final ReportModel report;
  const _HeaderCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.fireLevel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  report.address ?? '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline step ─────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final String? timestamp;
  final String? note;
  final String? respondedBy;
  final bool isRejected;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.timestamp,
    this.note,
    this.respondedBy,
    this.isRejected = false,
  });

  Color get _dotColor {
    if (isRejected) return Colors.red;
    if (isCurrent) return AppColors.primary;
    if (isDone) return AppColors.statusAttended;
    return const Color(0xFFDCE5DC);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Coluna da linha + dot ─────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? _dotColor.withValues(alpha: 0.15)
                        : const Color(0xFFF0F4F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: _dotColor, width: 2),
                  ),
                  child: Icon(icon,
                      size: 16,
                      color: isDone ? _dotColor : AppColors.textLight),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone
                          ? AppColors.statusAttended.withValues(alpha: 0.3)
                          : const Color(0xFFDCE5DC),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Conteúdo do step ──────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isDone ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      timestamp!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                  if (!isDone && timestamp == null) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'aguardando...',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCE5DC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OBSERVAÇÃO DA AUTORIDADE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMedium),
                          ),
                          if (respondedBy != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Por: $respondedBy',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  Color get _color {
    if (score >= 75) return const Color(0xFFE65100);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFF2E7D32);
  }

  String get _label {
    if (score >= 75) return 'CRÍTICO';
    if (score >= 50) return 'ALTO';
    return 'MODERADO';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _color, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(fontSize: 9, color: _color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prioridade: $_label',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Score calculado pelo sistema\ncom base no nível de fogo e localização.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
