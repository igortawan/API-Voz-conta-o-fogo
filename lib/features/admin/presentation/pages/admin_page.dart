// ============================================================================
// admin_page.dart
// ----------------------------------------------------------------------------
// Painel do Administrador — tela exclusiva para usuários com role 'admin'.
//
// Estrutura:
//   • AppBar com TabBar de 2 abas:
//       1. "Denúncias" — lista todas as denúncias com filtro e resumo
//       2. "Usuários"  — lista todos os usuários cadastrados no Firestore
//
// Aba 1 — Denúncias:
//   • _SummaryBar: faixa com Total, Pendentes, Em Análise, Atendidas
//   • _FilterRow: chips "Ativos / Atendidas / Todos" (filtro de exibição)
//   • ReportCard (da authority_page.dart) com hideActions=true, readOnly=true
//     → sem botão "Alterar Status" (admin observa, não opera)
//   • Toque no card → ReportDetailPage(readOnly: true)
//
// Aba 2 — Usuários:
//   • _UsersTab: lista de _UserCard com avatar, nome, e-mail e badge de papel
//   • Ícone de engrenagem → _RoleSheet (bottom sheet para trocar o papel)
//   • _RoleSheet chama FirestoreService.setUserRole(uid, newRole)
//     → muda o campo 'role' no Firestore → NavigationPage detecta mudança via
//       currentUserRoleProvider (StreamProvider) e redireciona automaticamente
//
// Logout:
//   • AlertDialog de confirmação (mesmo padrão da AuthorityPage)
//   • AuthService.signOut() + pushAndRemoveUntil → LoginPage
//
// Providers utilizados:
//   • allReportsProvider   — StreamProvider<List<ReportModel>>
//   • allUsersProvider     — StreamProvider<List<Map<String,dynamic>>>
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../authority/presentation/pages/authority_page.dart';
import '../../../authority/presentation/pages/report_detail_page.dart';
import '../../../presentation/pages/auth/login.page.dart';
import '../../../report/data/models/report_model.dart';
import '../controllers/admin_controller.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

/// Painel de administração com visão global de denúncias e gerenciamento de usuários.
///
/// Usa [ConsumerStatefulWidget] para:
///   • Controlar o [TabController] (SingleTickerProviderStateMixin)
///   • Manter o filtro de status selecionado na aba de denúncias
///   • Assistir [allReportsProvider] via ref.watch
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  /// Controlador das 2 abas (Denúncias / Usuários)
  late final TabController _tabs;

  /// Filtro de denúncias: 'ativos' | 'atendida' | 'todos'
  String _filter = 'ativos'; // padrão: mostra apenas casos em aberto

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose(); // libera recursos do TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stream em tempo real de todas as denúncias do Firestore
    final reportsAsync = ref.watch(allReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Painel Admin'),
        automaticallyImplyLeading: false, // sem botão voltar (tela raiz)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        // TabBar integrada ao AppBar (aparece abaixo do título)
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department), text: 'Denúncias'),
            Tab(icon: Icon(Icons.people_outline), text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Aba 1: Denúncias ────────────────────────────────────────────
          reportsAsync.when(
            data: (all) {
              // Aplica filtro selecionado (ativos / atendidas / todos)
              final filtered = _applyFilter(all);
              return Column(
                children: [
                  // Faixa de resumo com contagem por status
                  _SummaryBar(reports: all),
                  // Chips de filtro horizontal
                  _FilterRow(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  // Lista de cards ou estado vazio
                  Expanded(
                    child: filtered.isEmpty
                        ? const _EmptyReports()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => ReportCard(
                              report: filtered[i],
                              // Admin pode visualizar detalhes mas não editar status
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailPage(
                                    report: filtered[i],
                                    readOnly: true, // sem botões de ação
                                  ),
                                ),
                              ),
                              onChangeStatus: () {}, // noop — admin não opera
                              hideActions: true,      // oculta botão "Alterar Status"
                            ),
                          ),
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          ),

          // ── Aba 2: Usuários ─────────────────────────────────────────────
          const _UsersTab(),
        ],
      ),
    );
  }

  /// Filtra a lista de denúncias conforme o chip selecionado.
  ///
  ///   • 'ativos'   → pendente, enviada, analisando (casos em aberto)
  ///   • 'atendida' → somente casos resolvidos
  ///   • 'todos'    → sem filtro (lista completa)
  List<ReportModel> _applyFilter(List<ReportModel> r) {
    switch (_filter) {
      case 'ativos':
        return r
            .where((x) =>
                x.status == AppConstants.statusPending ||
                x.status == AppConstants.statusSent ||
                x.status == AppConstants.statusAnalyzing)
            .toList();
      case 'atendida':
        return r
            .where((x) => x.status == AppConstants.statusAttended)
            .toList();
      default:
        return r; // 'todos' — sem filtro
    }
  }

  /// Exibe AlertDialog de confirmação e efetua logout.
  ///
  /// Mesmo padrão visual da AuthorityPage (OutlinedButton + ElevatedButton).
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
      // Remove toda a pilha de rotas → LoginPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}

// ── Barra de resumo (aba de denúncias) ────────────────────────────────────────

/// Faixa branca com 4 estatísticas das denúncias.
///
/// Exibe: Total | Pendentes | Em Análise | Atendidas
/// Cada coluna usa [_Tile] com número em destaque e label abaixo.
class _SummaryBar extends StatelessWidget {
  final List<ReportModel> reports;
  const _SummaryBar({required this.reports});

  @override
  Widget build(BuildContext context) {
    // Contagem por grupo de status
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _Tile(reports.length, 'Total', AppColors.primary),
          _vDiv(),
          _Tile(pending, 'Pendentes', Colors.orange),
          _vDiv(),
          _Tile(analyzing, 'Em Análise', Colors.purple),
          _vDiv(),
          _Tile(attended, 'Atendidas', Colors.green),
        ],
      ),
    );
  }

  /// Divisor vertical fino entre colunas de estatística.
  Widget _vDiv() =>
      Container(width: 1, height: 30, color: Colors.grey.shade200);
}

/// Coluna de estatística: número em destaque + label.
class _Tile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Tile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            // Número em cor do status
            Text('$value',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            // Label em cinza claro abaixo do número
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
          ],
        ),
      );
}

// ── Chips de filtro da aba de denúncias ───────────────────────────────────────

/// Filtros horizontais para a lista de denúncias do admin.
///
/// Opções: 'ativos' (padrão) | 'atendida' | 'todos'
/// Usa Records do Dart 3 para definir (chave, label).
class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Definição dos filtros disponíveis: (chave, label)
    const filters = [
      ('ativos',   'Ativos'),
      ('atendida', 'Atendidas'),
      ('todos',    'Todos'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: active,
              onSelected: (_) => onChanged(f.$1),
              selectedColor: AppColors.primary.withValues(alpha:0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: active ? AppColors.primary : AppColors.textMedium,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Aba de usuários ───────────────────────────────────────────────────────────

/// Aba que lista todos os usuários cadastrados no Firestore.
///
/// Usa [allUsersProvider] (StreamProvider) para dados em tempo real.
/// Cada usuário é exibido como [_UserCard] com avatar colorido por papel.
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream de todos os documentos da coleção 'users' no Firestore
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('Nenhum usuário cadastrado.',
                style: TextStyle(color: AppColors.textLight)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _UserCard(user: users[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

// ── Card de usuário ───────────────────────────────────────────────────────────

/// Card de um usuário com avatar colorido por papel, nome, e-mail e badge.
///
/// Botão de engrenagem (⚙) abre [_RoleSheet] para trocar o papel.
///
/// Dados do usuário (Map<String, dynamic> do Firestore):
///   • uid         — identificador único do Firebase Auth
///   • displayName — nome de exibição
///   • email       — e-mail de autenticação
///   • role        — 'user' | 'autoridade' | 'admin'
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    // Extrai dados do Map, com fallbacks para evitar nulos
    final uid   = user['uid']         as String? ?? '';
    final name  = user['displayName'] as String? ?? 'Sem nome';
    final email = user['email']       as String? ?? '';
    final role  = user['role']        as String? ?? AppConstants.roleUser;

    final roleLabel = _roleLabel(role);
    final roleColor = _roleColor(role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Avatar circular colorido com ícone do papel
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha:0.15),
            child: Icon(_roleIcon(role), color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Informações textuais: nome, e-mail e badge de papel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 4),
                // Badge colorido com o papel atual
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(roleLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: roleColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Botão de edição → abre _RoleSheet
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined,
                color: AppColors.textLight),
            onPressed: () => _showRoleSheet(context, uid, name, role),
          ),
        ],
      ),
    );
  }

  /// Abre o bottom sheet de troca de papel para o usuário.
  void _showRoleSheet(
      BuildContext context, String uid, String name, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoleSheet(uid: uid, name: name, currentRole: currentRole),
    );
  }

  /// Retorna o label legível para o papel informado.
  String _roleLabel(String r) {
    switch (r) {
      case AppConstants.roleAdmin:
        return 'Admin';
      case AppConstants.roleAuthority:
        return 'Autoridade';
      default:
        return 'Usuário';
    }
  }

  /// Retorna a cor do badge baseada no papel do usuário.
  Color _roleColor(String r) {
    switch (r) {
      case AppConstants.roleAdmin:
        return Colors.red;    // admin: vermelho
      case AppConstants.roleAuthority:
        return Colors.blue;   // autoridade: azul
      default:
        return AppColors.primary; // usuário comum: verde
    }
  }

  /// Retorna o ícone do avatar baseado no papel do usuário.
  IconData _roleIcon(String r) {
    switch (r) {
      case AppConstants.roleAdmin:
        return Icons.admin_panel_settings; // escudo com engrenagem
      case AppConstants.roleAuthority:
        return Icons.security;             // escudo
      default:
        return Icons.person;               // pessoa
    }
  }
}

// ── Bottom sheet de troca de papel ───────────────────────────────────────────

/// Modal para o admin alterar o papel (role) de um usuário.
///
/// Exibe as 3 opções de papel como [ListTile]s.
/// O papel atual é destacado com check e negrito.
///
/// Ao selecionar um novo papel:
///   1. [FirestoreService.setUserRole(uid, newRole)] atualiza o Firestore
///   2. O [currentUserRoleProvider] no NavigationPage detecta a mudança
///   3. O usuário afetado é redirecionado automaticamente na próxima
///      consulta (via ref.listen na NavigationPage)
class _RoleSheet extends StatefulWidget {
  final String uid;
  final String name;
  final String currentRole;
  const _RoleSheet(
      {required this.uid, required this.name, required this.currentRole});

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  /// Indica requisição em andamento para mostrar indicador de progresso
  bool _loading = false;

  /// Chama o Firestore para atualizar o papel e fecha o sheet.
  Future<void> _setRole(String newRole) async {
    setState(() => _loading = true);
    try {
      // TODO: implementar endpoint Django PATCH /accounts/{uid}/role/
      // await DjangoUserService.setUserRole(widget.uid, newRole);
      // Por ora, exibe aviso temporário
      throw Exception('Gerenciamento de roles via painel admin em implementação.');
      if (mounted) Navigator.pop(context); // fecha o sheet após sucesso
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
    // Definição dos papéis disponíveis: (chave, label, ícone, cor)
    final roles = [
      (AppConstants.roleUser,      'Usuário',    Icons.person,                AppColors.primary),
      (AppConstants.roleAuthority, 'Autoridade', Icons.security,               Colors.blue),
      (AppConstants.roleAdmin,     'Admin',      Icons.admin_panel_settings,  Colors.red),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alterar Perfil',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // Nome do usuário que está sendo editado
          Text(widget.name,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 16),
          // Indicador de carregamento ou lista de opções de papel
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ...roles.map((r) => ListTile(
                  leading: Icon(r.$3, color: r.$4),
                  title: Text(r.$2,
                      style: TextStyle(
                          // Papel atual em negrito
                          fontWeight: widget.currentRole == r.$1
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  // Check mark para o papel atual
                  trailing: widget.currentRole == r.$1
                      ? Icon(Icons.check, color: r.$4)
                      : null,
                  onTap: () => _setRole(r.$1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                )),
        ],
      ),
    );
  }
}

// ── Estado vazio (aba de denúncias) ───────────────────────────────────────────

/// Exibido quando nenhuma denúncia corresponde ao filtro selecionado.
class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Nenhuma denúncia encontrada.',
                style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
}
