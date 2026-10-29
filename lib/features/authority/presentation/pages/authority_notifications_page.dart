// ============================================================================
// authority_notifications_page.dart
// ----------------------------------------------------------------------------
// Tela de alertas recentes da Autoridade — lista de denúncias ordenadas
// por data, agrupadas por dia com separadores textuais.
//
// Acesso: ícone de sino no AppBar da AuthorityPage.
//
// Funcionalidades:
//   • Lista as 50 denúncias mais recentes do Firestore (allReportsProvider)
//   • Agrupa por data: HOJE / ONTEM / DD/MM/YYYY
//   • Cada card (_NotificationCard) é clicável e navega para ReportDetailPage
//   • Marca todos como "vistos" ao abrir (initState → _markAllSeen)
//   • Tempo relativo: "agora", "X min atrás", "Xh atrás", ou hora HH:mm
//
// Lógica de "não lidos" (_markAllSeen):
//   • Salva DateTime.now() em Hive (chave: 'authority_last_seen')
//   • Atualiza [authorityLastSeenProvider] (StateProvider<DateTime>) via Riverpod
//   • [authorityUnreadCountProvider] recalcula contando denúncias após lastSeen
//   • O badge vermelho no sino de AuthorityPage volta a 0 automaticamente
//
// Widgets internos:
//   • [_NotificationCard] — card clicável com cor/ícone por urgência
//     e tempo relativo computado em getter
//   • [_EmptyNotifications] — estado vazio quando sem denúncias
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/local/hive_service.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
import '../../../report/data/models/report_model.dart';
import 'report_detail_page.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

/// Tela de alertas da autoridade — lista agrupada por data com marcação de lidos.
///
/// Usa [ConsumerStatefulWidget] para:
///   • Executar _markAllSeen() em initState (via addPostFrameCallback)
///   • Assistir [allReportsProvider] com ref.watch
class AuthorityNotificationsPage extends ConsumerStatefulWidget {
  const AuthorityNotificationsPage({super.key});

  @override
  ConsumerState<AuthorityNotificationsPage> createState() =>
      _AuthorityNotificationsPageState();
}

class _AuthorityNotificationsPageState
    extends ConsumerState<AuthorityNotificationsPage> {

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback garante que o widget já foi inserido na árvore
    // antes de chamar ref.read (necessário para atualizar o StateProvider)
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllSeen());
  }

  /// Marca todos os alertas como "vistos" ao entrar na tela.
  ///
  /// Persiste no Hive para sobreviver ao reinício do app.
  /// Atualiza o StateProvider em memória para zerar o badge imediatamente.
  void _markAllSeen() {
    final now = DateTime.now();
    // Persiste no Hive: key 'authority_last_seen' → ISO8601 string
    HiveService.saveSetting('authority_last_seen', now.toIso8601String());
    // Atualiza o provider em memória (badge do sino vai a 0 instantaneamente)
    ref.read(authorityLastSeenProvider.notifier).state = now;
  }

  @override
  Widget build(BuildContext context) {
    // Stream de todas as denúncias (mesma fonte da AuthorityPage)
    final reportsAsync = ref.watch(allReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alertas Recentes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) return const _EmptyNotifications();

          // Ordena do mais recente ao mais antigo e limita a 50 itens
          final sorted = [...reports]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final recent = sorted.take(50).toList();

          // Intercala strings de data como separadores de seção
          final groups = _groupByDate(recent);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final entry = groups[i];

              // String → separador de data (HOJE / ONTEM / DD/MM/YYYY)
              if (entry is String) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    entry,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }

              // ReportModel → card de notificação clicável
              final report = entry as ReportModel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NotificationCard(report: report),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  /// Intercala labels de data na lista de denúncias para criar grupos visuais.
  ///
  /// Retorna lista heterogênea: [String, ReportModel, String, ReportModel, ...]
  /// onde String é o label do grupo ("HOJE", "ONTEM", "28/05/2025").
  List<dynamic> _groupByDate(List<ReportModel> reports) {
    final result = <dynamic>[];
    String? lastLabel;

    for (final r in reports) {
      final label = _dateLabel(r.createdAt);
      // Insere label apenas quando muda o grupo de data
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(r);
    }
    return result;
  }

  /// Formata uma data em label legível para o separador de grupo.
  ///
  /// - Hoje  → 'HOJE'
  /// - Ontem → 'ONTEM'
  /// - Demais → 'DD/MM/YYYY' (maiúsculo)
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'HOJE';
    if (d == today.subtract(const Duration(days: 1))) return 'ONTEM';
    return DateFormat('dd/MM/yyyy').format(dt).toUpperCase();
  }
}

// ── Card de notificação ───────────────────────────────────────────────────────

/// Card clicável exibindo o resumo de uma denúncia como alerta.
///
/// Cor e ícone de urgência variam conforme [ReportModel.fireLevel]:
///   • fireLevelUrgent    → vermelho + ícone de aviso
///   • fireLevelNearHome  → laranja + ícone de casa
///   • fireLevelMedium    → âmbar + ícone de fogo
///   • outros             → verde + ícone de folha
///
/// Ao tocar navega para [ReportDetailPage] (modo leitura e edição).
class _NotificationCard extends StatelessWidget {
  final ReportModel report;
  const _NotificationCard({required this.report});

  /// Cor de acento baseada no nível de urgência.
  Color get _urgencyColor {
    switch (report.fireLevel) {
      case AppConstants.fireLevelUrgent:
        return const Color(0xFFD32F2F); // vermelho escuro
      case AppConstants.fireLevelNearHome:
        return const Color(0xFFE65100); // laranja escuro
      case AppConstants.fireLevelMedium:
        return const Color(0xFFF57F17); // âmbar
      default:
        return const Color(0xFF388E3C); // verde (florestal)
    }
  }

  /// Ícone associado ao nível de urgência.
  IconData get _urgencyIcon {
    switch (report.fireLevel) {
      case AppConstants.fireLevelUrgent:
        return Icons.warning_rounded;         // urgente
      case AppConstants.fireLevelNearHome:
        return Icons.home_outlined;           // próximo a residência
      case AppConstants.fireLevelMedium:
        return Icons.local_fire_department;   // médio
      default:
        return Icons.eco_outlined;            // florestal / pequeno
    }
  }

  /// Tempo relativo desde a criação da denúncia.
  ///
  /// - < 1 min  → 'agora'
  /// - < 60 min → 'X min atrás'
  /// - < 24h    → 'Xh atrás'
  /// - ≥ 24h    → hora no formato 'HH:mm'
  String get _relativeTime {
    final diff = DateTime.now().difference(report.createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return DateFormat('HH:mm').format(report.createdAt);
  }

  /// Localização formatada: endereço ou coordenadas decimais.
  String get _location {
    if (report.address != null && report.address!.isNotEmpty) {
      return report.address!;
    }
    return '${report.latitude.toStringAsFixed(4)}, '
        '${report.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor;

    return GestureDetector(
      // Navega para o detalhe completo ao tocar no card
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailPage(report: report),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          // Borda lateral colorida indica urgência visualmente
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Badge de urgência + tempo relativo ────────────────────────
            Row(
              children: [
                // Pill com ícone e nível de urgência em maiúsculo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_urgencyIcon, color: color, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        report.fireLevel.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Tempo relativo alinhado à direita
                Text(
                  _relativeTime,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),

            // ── Descrição (limitada a 110 caracteres) ─────────────────────
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report.description.length > 110
                    ? '${report.description.substring(0, 110)}…'
                    : report.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Localização + nível de fumaça ──────────────────────────────
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _location,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.cloud_outlined,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  report.smokeLevel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

/// Exibido quando não há denúncias registradas no sistema.
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhum alerta ainda.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight),
            ),
            const SizedBox(height: 6),
            const Text(
              'As novas denúncias aparecerão aqui.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      );
}
