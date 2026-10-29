// ============================================================================
// navigation_page.dart
// ----------------------------------------------------------------------------
// Navegação principal do cidadão — BottomAppBar com 4 abas + FAB central.
//
// Estrutura visual:
//   • BottomAppBar com notch circular para o FAB (FloatingActionButton)
//   • 4 abas: Home | Mapa | Prevenção | Perfil
//   • FAB central (ícone de fogo) → navega para ReportFirePage via push
//   • IndexedStack preserva o estado de cada aba ao trocar de tela
//
// Roteamento automático por role:
//   • Usa [currentUserRoleProvider] (StreamProvider) para escutar mudanças
//     de role em tempo real. Se o admin promover um usuário para 'autoridade'
//     ou 'admin', o app redireciona automaticamente sem precisar de logout.
//   • ref.listen() dispara só quando o valor muda, evitando loops.
//
// Providers locais:
//   • [_navIndexProvider] — StateProvider<int> que controla qual aba está ativa.
//     Privado (prefixo _) pois só é usado dentro deste arquivo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/network/connectivity_service.dart';
import '../core/theme/app_colors.dart';
import 'admin/presentation/controllers/admin_controller.dart';
import 'admin/presentation/pages/admin_page.dart';
import 'authority/presentation/pages/authority_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/map_page.dart';
import 'presentation/pages/prevention_page.dart';
import 'presentation/pages/profile_page.dart';
import 'presentation/pages/report_fire_page.dart';
import 'report/presentation/controllers/report_controller.dart';

/// Provider que controla o índice da aba ativa no BottomNavigationBar.
///
/// Privado ao arquivo — use [_navIndexProvider] internamente.
/// Iniciado em 0 (HomePage).
final _navIndexProvider = StateProvider<int>((ref) => 0);

/// Tela de navegação principal com BottomAppBar e FAB.
///
/// Usa [ConsumerWidget] pois precisa:
///   • Assistir [_navIndexProvider] para destacar o ícone ativo
///   • Escutar [currentUserRoleProvider] para redirecionar ao trocar de role
class NavigationPage extends ConsumerWidget {
  const NavigationPage({super.key});

  /// Lista estática das 4 abas.
  ///
  /// [IndexedStack] mantém todas as abas na memória simultaneamente,
  /// preservando o estado de scroll, formulários e dados carregados.
  /// Isso é preferível a Navigator.push pois evita recarregar dados ao voltar.
  ///
  /// PreventionPage(isTab: true) → oculta o botão de voltar (já está na nav).
  static const _pages = [
    HomePage(),
    MapPage(),
    PreventionPage(isTab: true),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_navIndexProvider);

    // ── Escuta mudanças de role em tempo real ─────────────────────────────
    // Quando o admin muda o role no Firebase Console (ou pelo painel admin),
    // o app redireciona automaticamente sem precisar de logout/login.
    //
    // pushAndRemoveUntil remove toda a pilha de navegação, evitando que o
    // usuário possa voltar para a NavigationPage após ser promovido.
    ref.listen<String>(currentUserRoleProvider, (_, role) {
      if (!context.mounted) return;
      if (role == AppConstants.roleAuthority) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthorityPage()),
          (_) => false,
        );
      } else if (role == AppConstants.roleAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
          (_) => false,
        );
      }
    });

    // ── Sincronização automática ao recuperar conexão ─────────────────────
    // O connectivityProvider emite true/false a cada mudança de rede.
    // Quando a transição é de OFFLINE → ONLINE, enfileira a sincronização
    // das denúncias pendentes (salvas no Hive com synced=false).
    //
    // Verificação prev?.value == false: garante que só sincroniza na
    // transição de offline para online, NÃO toda vez que o app abre
    // já com internet disponível (prev seria null na primeira emissão).
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOffline = prev?.value == false;
      final isNowOnline = next.value == true;
      if (wasOffline && isNowOnline) {
        // Dispara em fire-and-forget — falhas são silenciadas internamente
        ref.read(reportControllerProvider.notifier).syncPending();
      }
    });

    return Scaffold(
      // IndexedStack preserva o estado de todas as abas simultaneamente
      body: IndexedStack(index: index, children: _pages),

      // ── FAB central — ação principal de denúncia ──────────────────────
      // heroTag evita conflito de animação Hero quando múltiplos FABs existem
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 6,
        heroTag: 'report_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportFirePage()),
        ),
        child: const Icon(
          Icons.local_fire_department,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── BottomAppBar com notch para o FAB ────────────────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // recorte para o FAB
        notchMargin: 8,                          // espaço entre FAB e BottomBar
        color: AppColors.surface,
        elevation: 8,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Aba 0 — Home
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              isActive: index == 0,
              onTap: () => ref.read(_navIndexProvider.notifier).state = 0,
            ),
            // Aba 1 — Mapa
            _NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              isActive: index == 1,
              onTap: () => ref.read(_navIndexProvider.notifier).state = 1,
            ),
            // Espaço reservado para o FAB no centro
            const SizedBox(width: 56),
            // Aba 2 — Prevenção
            _NavItem(
              icon: Icons.eco_outlined,
              activeIcon: Icons.eco,
              isActive: index == 2,
              onTap: () => ref.read(_navIndexProvider.notifier).state = 2,
            ),
            // Aba 3 — Perfil
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              isActive: index == 3,
              onTap: () => ref.read(_navIndexProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item de navegação ─────────────────────────────────────────────────────────

/// Ícone clicável do BottomAppBar com estado ativo/inativo.
///
/// Usa ícone preenchido quando ativo e outline quando inativo,
/// com cores [AppColors.primary] e [AppColors.textLight] respectivamente.
class _NavItem extends StatelessWidget {
  final IconData icon;       // ícone outline (inativo)
  final IconData activeIcon; // ícone preenchido (ativo)
  final bool isActive;       // se esta aba está selecionada
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.textLight,
          size: 26,
        ),
      ),
    );
  }
}
