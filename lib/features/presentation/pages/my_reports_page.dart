// ============================================================================
// my_reports_page.dart
// ----------------------------------------------------------------------------
// Tela "Minhas Denúncias" — histórico de ocorrências do usuário logado.
//
// Estratégia de exibição:
//   • Usuário anônimo → exibe apenas denúncias do Hive (offline) via
//     [_OfflineReportsList], pois não tem uid para consultar o Firestore.
//   • Usuário autenticado → combina:
//       1. Denúncias pendentes locais (Hive, synced=false) — aparecem primeiro
//       2. Denúncias sincronizadas no Firestore (stream em tempo real)
//     Se o Firestore falhar, cai no fallback offline (_OfflineReportsList).
//
// Indicadores visuais:
//   • Badge de status (Offline | Pendente | Enviada | Em análise | Atendida)
//   • Badge "Anônima" para denúncias feitas em modo anônimo
//   • Indicador ☁️ "Aguardando conexão" para denúncias não sincronizadas
//   • Observações da autoridade (campo 'observations') ao final do card
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../report/data/models/report_model.dart';
import '../../report/presentation/controllers/report_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'my_report_detail_page.dart';

// ── Página principal ──────────────────────────────────────────────────────────

/// Tela de histórico de denúncias do usuário.
///
/// Decide qual sub-widget exibir com base no estado de autenticação.
class MyReportsPage extends ConsumerWidget {
  const MyReportsPage({super.key});

  AppBar _buildAppBar(BuildContext context) => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Minhas Denúncias'),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(authStateProvider)?.isAnonymous ?? true;

    // Usuário anônimo não tem uid → exibe apenas cache local
    if (isAnonymous) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: const _OfflineBody(),
      );
    }

    // Usuário autenticado → tenta buscar do Firestore em tempo real
    final reportsAsync = ref.watch(userReportsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: reportsAsync.when(
        data: (reports) {
          final localReports = ref.watch(localReportsProvider);

          // Somente reports não sincronizados (synced=false); os com synced=true
          // já estão no stream do Firestore — evita duplicatas.
          final pending = localReports.where((r) => !r.synced).toList();
          final firestoreIds = reports.map((r) => r.id).toSet();
          final trulyPending =
              pending.where((r) => !firestoreIds.contains(r.id)).toList();

          final all = [...trulyPending, ...reports];

          if (all.isEmpty) return const _EmptyState();
          return _ReportList(reports: all);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // Fallback: Firestore inacessível → exibe apenas o cache local filtrado
        error: (e, _) => const _OfflineBody(),
      ),
    );
  }
}

// ── Body offline ──────────────────────────────────────────────────────────────

/// Corpo da lista de denúncias do cache local (Hive), sem Scaffold próprio.
///
/// Usado em dois casos:
///   1. Usuário anônimo — envolvido pelo Scaffold de MyReportsPage
///   2. Fallback de erro do Firestore — body do Scaffold de MyReportsPage
class _OfflineBody extends ConsumerWidget {
  const _OfflineBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(localReportsProvider);
    return reports.isEmpty
        ? const _EmptyState()
        : _ReportList(reports: reports);
  }
}

// ── Lista de denúncias ────────────────────────────────────────────────────────

/// ListView com separadores que exibe a lista de [ReportModel].
class _ReportList extends StatelessWidget {
  final List<ReportModel> reports;
  const _ReportList({required this.reports});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ReportCard(report: reports[i]),
    );
  }
}

// ── Card de denúncia ──────────────────────────────────────────────────────────

/// Card visual representando uma denúncia individual do usuário.
///
/// Ao tocar navega para [MyReportDetailPage] exibindo todos os detalhes.
///
/// Exibe: status (badge colorido), data, nível do fogo, badge "Anônima",
/// descrição (2 linhas max), coordenadas, indicador offline e observações.
class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt);

    // Material + InkWell: garante o efeito ripple sobre o card branco
    // sem conflitar com o BoxDecoration do Container interno.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Toque → abre os detalhes completos da denúncia
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyReportDetailPage(report: report),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: status + data + seta indicativa ──────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: report.status, synced: report.synced),
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Seta sutil indicando que o card é tappável
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Nível do fogo + score + badge anônima ──────────────────
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.fireLevel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (report.score != null) ...[
                _ScoreChip(score: report.score!),
                const SizedBox(width: 6),
              ],
              if (report.anonymous)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Anônima',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ),
            ],
          ),

          // ── Descrição (até 2 linhas) ────────────────────────────────
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // ── Coordenadas GPS ─────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),

          // ── Indicador offline ────────────────────────────────────────
          // Exibido apenas para denúncias ainda não sincronizadas com o servidor
          if (!report.synced) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
                SizedBox(width: 6),
                Text(
                  'Aguardando conexão para sincronizar',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // ── Observação da autoridade ─────────────────────────────────
          // Campo preenchido pelo painel de autoridade ao responder a denúncia
          if (report.observations != null &&
              report.observations!.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Observação: ${report.observations}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],         // fim da lista children da Column
          ),       // fecha Column
        ),         // fecha Padding
      ),           // fecha InkWell
    );             // fecha Material (return statement)
  }
}

// ── Badge de status ───────────────────────────────────────────────────────────

/// Badge colorido que indica o status atual de uma denúncia.
///
/// Casos especiais:
///   • synced=false → exibe "Offline" em cinza (aguardando sincronização)
///   • Os demais status usam as cores definidas em [AppColors]
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool synced;
  const _StatusBadge({required this.status, required this.synced});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status, synced);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo colorido indicador
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: config.$1, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            config.$2,
            style: TextStyle(
              color: config.$1,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna (cor, label) para o status informado.
  /// Usa Record do Dart 3 (tupla de dois valores).
  (Color, String) _statusConfig(String status, bool synced) {
    if (!synced) return (AppColors.textLight, 'Offline');
    switch (status) {
      case AppConstants.statusPending:
        return (AppColors.statusPending, 'Pendente');
      case AppConstants.statusSent:
        return (AppColors.statusSent, 'Enviada');
      case AppConstants.statusAnalyzing:
        return (AppColors.statusAnalyzing, 'Em análise');
      case AppConstants.statusAttended:
        return (AppColors.statusAttended, 'Atendida');
      default:
        return (AppColors.textLight, status); // status desconhecido → texto bruto
    }
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

// ── Score chip ────────────────────────────────────────────────────────────────

/// Badge colorido com o score de prioridade calculado pelo Django (0–100).
class _ScoreChip extends StatelessWidget {
  final int score;
  const _ScoreChip({required this.score});

  Color get _color {
    if (score >= 75) return const Color(0xFFE65100);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '🔥 $score',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

/// Widget exibido quando o usuário ainda não tem nenhuma denúncia registrada.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma denúncia ainda.',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque no botão de fogo para reportar um incêndio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
