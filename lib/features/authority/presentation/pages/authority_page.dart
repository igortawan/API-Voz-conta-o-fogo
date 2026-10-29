// ============================================================================
// authority_page.dart
// ----------------------------------------------------------------------------
// Painel da Autoridade — tela exclusiva para usuários com role 'autoridade'.
//
// Funcionalidades:
//   • Lista todas as denúncias em tempo real via [allReportsProvider]
//   • Barra de resumo estatístico (_SummaryBar) com contagem por status
//   • Filtro horizontal de status (_FilterRow) com chips clicáveis
//   • Card de denúncia ([ReportCard]) com acento colorido por urgência
//   • Bottom sheet para alterar status ([StatusSheet])
//   • Badge de notificações não lidas no ícone de sino
//   • Logout com diálogo de confirmação
//
// Inicialização (initState):
//   • Assina o tópico FCM 'authority_alerts' para receber push notifications
//     de novas denúncias, mesmo com o app em background
//
// Widgets públicos exportados (usados também no AdminPage):
//   • [ReportCard]  — card de denúncia com borda lateral colorida
//   • [StatusSheet] — bottom sheet de troca de status
//
// Estrutura de dados:
//   • [allReportsProvider] → StreamProvider<List<ReportModel>> em Firestore
//   • [authorityUnreadCountProvider] → Provider<int> baseado em authorityLastSeen
//
// Fluxo de atualização de status:
//   1. Autoridade toca "Alterar Status" → _showStatusSheet()
//   2. StatusSheet.setStatus() → FirestoreService.updateReportStatus()
//   3. Firestore atualiza o documento e dispara FCM para o denunciante
//   4. Stream recarrega → UI atualiza automaticamente
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/firebase/fcm_service.dart';
import '../../../../services/api/django_report_service.dart';
import '../../../admin/presentation/controllers/admin_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../presentation/pages/auth/login.page.dart';
import '../../../report/data/models/report_model.dart';
import 'authority_notifications_page.dart';
import 'authority_stats_page.dart';
import 'report_detail_page.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

/// Painel de gerenciamento de denúncias para usuários com papel 'autoridade'.
///
/// Usa [ConsumerStatefulWidget] para:
///   • Subscrever o tópico FCM em initState()
///   • Manter o filtro de status selecionado (_filter)
///   • Assistir [allReportsProvider] e [authorityUnreadCountProvider]
class AuthorityPage extends ConsumerStatefulWidget {
  const AuthorityPage({super.key});

  @override
  ConsumerState<AuthorityPage> createState() => _AuthorityPageState();
}

class _AuthorityPageState extends ConsumerState<AuthorityPage>
    with SingleTickerProviderStateMixin {
  /// Status selecionado no filtro. 'todos' exibe todas as denúncias.
  String _filter = 'todos';

  /// Controla as duas abas: Denúncias (0) e Estatísticas (1).
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    FcmService.subscribeToTopic(AppConstants.fcmAuthorityTopic);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider);
    final unread = ref.watch(authorityUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(unread),
      body: reportsAsync.when(
        data: (all) {
          final filtered = _applyFilter(all);
          return Column(
            children: [
              // ── TabBar: Denúncias | Estatísticas ──────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textLight,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.list_alt_rounded), text: 'Denúncias'),
                    Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Estatísticas'),
                  ],
                ),
              ),

              // ── Conteúdo das abas ────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Aba 0 — Lista de denúncias
                    Column(
                      children: [
                        _SummaryBar(reports: all),
                        _FilterRow(
                          selected: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, i) => ReportCard(
                                    report: filtered[i],
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReportDetailPage(report: filtered[i]),
                                      ),
                                    ),
                                    onChangeStatus: () =>
                                        _showStatusSheet(filtered[i]),
                                  ),
                                ),
                        ),
                      ],
                    ),

                    // Aba 1 — Estatísticas
                    AuthorityStatsPage(reports: all),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  /// Constrói a AppBar com sino de notificações (badge) e botão de logout.
  ///
  /// O badge vermelho exibe o número de denúncias recebidas após
  /// o último acesso à [AuthorityNotificationsPage] (salvo no Hive).
  AppBar _buildAppBar(int unread) {
    return AppBar(
      title: const Text('Painel da Autoridade'),
      automaticallyImplyLeading: false, // sem botão voltar (tela raiz)
      actions: [
        // ── Sino com badge de não lidos ────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Alertas recentes',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthorityNotificationsPage(),
                ),
              ),
            ),
            // Badge vermelho com contagem (exibido apenas se unread > 0)
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 9 ? '9+' : '$unread', // limita a "9+"
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Botão de logout — abre diálogo de confirmação
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: _logout,
        ),
      ],
    );
  }

  // ── Filtro de status ──────────────────────────────────────────────────────

  /// Filtra a lista de denúncias pelo status selecionado.
  ///
  /// 'todos' retorna a lista completa sem filtro.
  /// Qualquer outro valor filtra por [ReportModel.status] exato.
  List<ReportModel> _applyFilter(List<ReportModel> r) {
    if (_filter == 'todos') return r;
    return r.where((x) => x.status == _filter).toList();
  }

  // ── Bottom sheet de status ────────────────────────────────────────────────

  /// Exibe o [StatusSheet] em um modal bottom sheet com bordas arredondadas.
  ///
  /// isScrollControlled: true permite que o sheet suba com o teclado virtual,
  /// necessário porque o StatusSheet agora tem um TextField de observações.
  void _showStatusSheet(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatusSheet(report: report),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Exibe diálogo de confirmação antes de deslogar.
  ///
  /// Ao confirmar:
  ///   1. Chama [AuthService.signOut()] — desloga do Firebase e limpa Hive
  ///   2. Navega para [LoginPage] com pushAndRemoveUntil (limpa pilha)
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Sair da conta'),
          ],
        ),
        content: const Text(
          'Deseja sair da conta e voltar à tela de login?',
          style: TextStyle(fontSize: 14, color: AppColors.textMedium),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      // Remove toda a pilha de rotas → LoginPage (sem botão voltar)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

// ── Barra de resumo estatístico ───────────────────────────────────────────────

/// Faixa horizontal com contagem de denúncias por status.
///
/// Exibe 5 colunas: Total, Pendentes, Em Análise, Atendidas, Rejeitadas.
/// Cada coluna é um [_StatCard] com ícone colorido, número e label.
class _SummaryBar extends StatelessWidget {
  final List<ReportModel> reports;
  const _SummaryBar({required this.reports});

  @override
  Widget build(BuildContext context) {
    // Conta denúncias por grupo de status
    final pending = reports
        .where((r) =>
            r.status == AppConstants.statusPending ||
            r.status == AppConstants.statusSent)
        .length;
    final analyzing = reports
        .where((r) => r.status == AppConstants.statusAnalyzing)
        .length;
    final attended = reports
        .where((r) => r.status == AppConstants.statusAttended)
        .length;
    final rejected = reports
        .where((r) => r.status == AppConstants.statusRejected)
        .length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        children: [
          _StatCard(reports.length, 'Total',
              Icons.description_outlined, AppColors.primary),
          _StatCard(pending, 'Pendentes',
              Icons.hourglass_top_rounded, AppColors.statusPending),
          _StatCard(analyzing, 'Em Análise',
              Icons.manage_search_rounded, AppColors.statusAnalyzing),
          _StatCard(attended, 'Atendidas',
              Icons.check_circle_outline, AppColors.statusAttended),
          _StatCard(rejected, 'Rejeitadas',
              Icons.cancel_outlined, AppColors.statusRejected),
        ],
      ),
    );
  }
}

/// Coluna estatística individual: ícone + número + label.
class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone dentro de círculo colorido semitransparente
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            // Número em destaque com a cor do status
            Text(
              '$value',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            // Label abreviada (max 1 linha com ellipsis)
            Text(
              label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textLight),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

// ── Linha de filtros por status ───────────────────────────────────────────────

/// Chips horizontais para filtrar a lista de denúncias por status.
///
/// Lista de filtros definida como Records do Dart 3: (valor, label, cor).
/// O chip selecionado fica com fundo colorido e borda mais espessa.
class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  /// Definição dos filtros: (chave de status, label exibido, cor do chip)
  static const _filters = [
    ('todos',                      'Todos',       AppColors.primary),
    (AppConstants.statusPending,   'Pendente',    AppColors.statusPending),
    (AppConstants.statusSent,      'Enviada',     AppColors.statusSent),
    (AppConstants.statusAnalyzing, 'Em Análise',  AppColors.statusAnalyzing),
    (AppConstants.statusAttended,  'Atendida',    AppColors.statusAttended),
    (AppConstants.statusRejected,  'Rejeitada',   AppColors.statusRejected),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: _filters.map((f) {
          final value  = f.$1;
          final label  = f.$2;
          final color  = f.$3;
          final active = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: active,
              onSelected: (_) => onChanged(value),
              backgroundColor: Colors.white,
              selectedColor: color.withValues(alpha: 0.15),
              checkmarkColor: color,
              // Borda mais grossa quando ativo
              side: BorderSide(
                color: active ? color : Colors.grey.shade300,
                width: active ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                color: active ? color : AppColors.textMedium,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Card de denúncia ──────────────────────────────────────────────────────────

/// Card visual de uma denúncia — compartilhado entre AuthorityPage e AdminPage.
///
/// Parâmetros:
///   • [report]        — dados da denúncia
///   • [onTap]         — navega para ReportDetailPage ao tocar no card
///   • [onChangeStatus] — abre StatusSheet ao tocar no botão de edição
///   • [hideActions]   — oculta o botão "Alterar Status" (usado no AdminPage)
///
/// Acento lateral colorido por urgência:
///   • fireLevelUrgent    → vermelho escuro  (#D32F2F)
///   • fireLevelNearHome  → laranja escuro   (#E65100)
///   • fireLevelMedium    → amarelo          (#F57F17)
///   • outros (florestal) → verde            (#388E3C)
class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;
  final VoidCallback onChangeStatus;

  /// Quando true, oculta o botão de alterar status (modo leitura do admin)
  final bool hideActions;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    required this.onChangeStatus,
    this.hideActions = false,
  });

  /// Cor de acento lateral baseada no nível de urgência da denúncia.
  Color get _urgencyAccent {
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

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yy HH:mm').format(report.createdAt);
    // Obtém cor e label do status atual (Dart 3 Records)
    final sc   = _statusConfig(report.status);
    final accent = _urgencyAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Borda lateral colorida indica urgência visualmente
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho: badge de status + data de criação ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  _StatusBadge(color: sc.$1, label: sc.$2),
                  const Spacer(),
                  Icon(Icons.access_time_rounded,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),

            // ── Nível do fogo + badge "Anônima" ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: accent, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      report.fireLevel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: accent,
                      ),
                    ),
                  ),
                  // Badge "Anônima" quando o denunciante optou pelo anonimato
                  if (report.anonymous)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Anônima',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight)),
                    ),
                ],
              ),
            ),

            // ── Descrição (limitada a 2 linhas) ─────────────────────────
            if (report.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium, height: 1.4),
                ),
              ),

            // ── Localização (endereço ou coordenadas) + nível de fumaça ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      // Exibe endereço se disponível, senão coordenadas brutas
                      report.address != null && report.address!.isNotEmpty
                          ? report.address!
                          : '${report.latitude.toStringAsFixed(4)}, '
                              '${report.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.cloud_outlined,
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(report.smokeLevel,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),

            // ── Botão "Alterar Status" (oculto no modo admin) ────────────
            if (!hideActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onChangeStatus,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Alterar Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 12), // espaçamento quando sem botão
          ],
        ),
      ),
    );
  }

  /// Retorna (cor, label) para o status informado usando Dart 3 Records.
  (Color, String) _statusConfig(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return (AppColors.statusPending, 'Pendente');
      case AppConstants.statusSent:
        return (AppColors.statusSent, 'Enviada');
      case AppConstants.statusAnalyzing:
        return (AppColors.statusAnalyzing, 'Em Análise');
      case AppConstants.statusAttended:
        return (AppColors.statusAttended, 'Atendida');
      case AppConstants.statusRejected:
        return (AppColors.statusRejected, 'Rejeitada');
      default:
        return (AppColors.textLight, status); // fallback para status desconhecido
    }
  }
}

// ── Badge de status ───────────────────────────────────────────────────────────

/// Pill colorido com ponto indicador e texto do status.
///
/// Exibido no cabeçalho de cada [ReportCard].
class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ponto indicador de cor sólida
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      );
}

// ── Bottom sheet de troca de status ──────────────────────────────────────────

/// Modal bottom sheet para alterar o status de uma denúncia.
///
/// Exibe as 4 opções de status (Enviada, Em Análise, Atendida, Rejeitada)
/// como [ListTile]s. O status atual é destacado com check e fundo colorido.
///
/// Ao selecionar:
///   1. [FirestoreService.updateReportStatus] atualiza o Firestore
///   2. O back-end dispara FCM para o denunciante (via Cloud Function)
///   3. O bottom sheet fecha automaticamente
///
/// Público pois é também reutilizado por [AuthorityNotificationsPage].
class StatusSheet extends StatefulWidget {
  final ReportModel report;
  const StatusSheet({super.key, required this.report});

  @override
  State<StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<StatusSheet> {
  /// Indica requisição em andamento para desabilitar interação
  bool _loading = false;

  /// Campo de texto para a autoridade registrar observações sobre a ocorrência.
  final _obsController = TextEditingController();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  /// Executa a troca de status no Firestore (com observações opcionais) e fecha o sheet.
  Future<void> _setStatus(String newStatus) async {
    setState(() => _loading = true);
    try {
      await DjangoReportService.updateReportStatus(
        reportId: widget.report.id,
        status: newStatus,
        observations: _obsController.text.trim().isNotEmpty
            ? _obsController.text.trim()
            : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definição das opções de status: (chave, label, cor, ícone)
    final options = [
      (AppConstants.statusSent, 'Enviada',
          AppColors.statusSent, Icons.send_outlined),
      (AppConstants.statusAnalyzing, 'Em Análise',
          AppColors.statusAnalyzing, Icons.manage_search_rounded),
      (AppConstants.statusAttended, 'Atendida',
          AppColors.statusAttended, Icons.check_circle_outline),
      (AppConstants.statusRejected, 'Rejeitada',
          AppColors.statusRejected, Icons.cancel_outlined),
    ];

    // Padding extra na base para o teclado virtual não sobrepor o conteúdo
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alça de arraste (drag handle) padrão de Material bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Alterar Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          // Subtítulo com o nível do fogo da denúncia
          Text(widget.report.fireLevel,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 4),
          // Aviso de que o denunciante será notificado
          const Text(
            'O denunciante receberá uma notificação ao atualizar.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),

          // ── Campo de observações (opcional) ───────────────────────────
          TextField(
            controller: _obsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Observações (opcional) — ex: equipe foi ao local, fogo controlado...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Indicador de carregamento ou lista de opções
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ...options.map((o) {
              final isCurrent = widget.report.status == o.$1;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: o.$3.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(o.$4, color: o.$3, size: 18),
                ),
                title: Text(
                  o.$2,
                  style: TextStyle(
                    color: o.$3,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isCurrent
                    ? Icon(Icons.check_rounded, color: o.$3)
                    : const Icon(Icons.chevron_right,
                        color: AppColors.textLight),
                onTap: () => _setStatus(o.$1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: isCurrent
                    ? o.$3.withValues(alpha: 0.05)
                    : null,
              );
            }),
        ],
        ),      // fecha Column
      ),        // fecha SingleChildScrollView
    );
  }
}

// ── Estado vazio ──────────────────────────────────────────────────────────────

/// Exibido quando nenhuma denúncia corresponde ao filtro selecionado.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma denúncia encontrada.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight),
            ),
          ],
        ),
      );
}
