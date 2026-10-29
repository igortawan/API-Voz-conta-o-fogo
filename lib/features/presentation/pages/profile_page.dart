// ============================================================================
// profile_page.dart
// ----------------------------------------------------------------------------
// Tela de Perfil do usuário — 4ª aba da NavigationPage.
//
// Seções:
//   1. Avatar + nome + e-mail (ou "Usuário Anônimo" + aviso de modo convidado)
//   2. "Sobre o Projeto" — informações do IFPI/FAPEPI e abrangência geográfica
//   3. "Contatos de Emergência" — Bombeiros, Defesa Civil, PM, IBAMA com LIGAR
//   4. "Links Úteis" — INPE, NASA FIRMS, IFPI (abrem no navegador)
//   5. Botão de logout com diálogo de confirmação
//   6. Rodapé com versão do app e crédito institucional
//
// Widgets reutilizáveis:
//   • [_InfoSection]  — seção com título verde e container com sombra
//   • [_InfoTile]     — linha simples com ícone + título + subtítulo
//   • [_PhoneTile]    — linha clicável que discagem via url_launcher (tel:)
//   • [_LinkTile]     — linha clicável que abre URL no navegador
//
// Logout:
//   • Exibe AlertDialog de confirmação antes de deslogar (UX consistente
//     com AuthorityPage e AdminPage que têm o mesmo padrão)
//   • Chama AuthController.signOut() → limpa Hive + Firebase Auth
//   • pushAndRemoveUntil → LoginPage (sem voltar para a NavigationPage)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'auth/login.page.dart';

/// Tela de perfil exibida na 4ª aba da NavigationPage.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(authStateProvider);
    final isAnonymous = appUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Avatar circular ──────────────────────────────────────
              // Ícone diferente para usuário anônimo (person_off) vs. autenticado
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isAnonymous ? Icons.person_off : Icons.person,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 16),

              // ── Nome do usuário ──────────────────────────────────────
              // Prioridade: displayName → email → fallback 'Cidadão'
              Text(
                isAnonymous
                    ? 'Usuário Anônimo'
                    : (appUser?.displayName ?? appUser?.email ?? 'Cidadão'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ── E-mail (só para usuários autenticados) ───────────────
              if (!isAnonymous && appUser?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  appUser!.email!,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],

              // ── Aviso de modo convidado ──────────────────────────────
              // Informa ao usuário anônimo que seus dados são locais apenas
              if (isAnonymous) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Modo convidado — dados não salvos na nuvem',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Seção: Sobre o Projeto ───────────────────────────────
              _InfoSection(
                title: 'Sobre o Projeto',
                children: [
                  _InfoTile(
                    icon: Icons.info_outline,
                    title: 'Voz Contra o Fogo',
                    subtitle: 'IFPI — Campus Paulistana • FAPEPI 2025',
                  ),
                  _InfoTile(
                    icon: Icons.location_city,
                    title: 'Abrangência',
                    subtitle: 'Paulistana, Jaicós, Acauã — Piauí',
                  ),
                  _InfoTile(
                    icon: Icons.eco,
                    title: 'Bioma',
                    subtitle: 'Caatinga • Semiárido Piauiense',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Seção: Contatos de Emergência ───────────────────────
              // Cada tile é clicável e discam via url_launcher (tel:número)
              _InfoSection(
                title: 'Contatos de Emergência',
                children: [
                  _PhoneTile(
                    icon: Icons.fire_truck,
                    title: 'Bombeiros',
                    phone: AppConstants.phoneFireDepartment,
                    iconColor: Colors.red,
                  ),
                  _PhoneTile(
                    icon: Icons.security,
                    title: 'Defesa Civil',
                    phone: AppConstants.phoneCivilDefense,
                    iconColor: Colors.blue,
                  ),
                  _PhoneTile(
                    icon: Icons.local_police,
                    title: 'Polícia Militar',
                    phone: AppConstants.phoneMilitaryPolice,
                    iconColor: Colors.indigo,
                  ),
                  _PhoneTile(
                    icon: Icons.eco,
                    title: 'IBAMA Linha Verde',
                    phone: AppConstants.phoneIbama,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Seção: Links Úteis ───────────────────────────────────
              // Abre URLs externas no navegador padrão do dispositivo
              _InfoSection(
                title: 'Links Úteis',
                children: [
                  _LinkTile(
                    icon: Icons.satellite_alt,
                    title: 'INPE — Monitoramento Queimadas',
                    url: 'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/',
                  ),
                  _LinkTile(
                    icon: Icons.public,
                    title: 'NASA FIRMS — Focos de Incêndio',
                    url: 'https://firms.modaps.eosdis.nasa.gov',
                  ),
                  _LinkTile(
                    icon: Icons.school,
                    title: 'IFPI — Campus Paulistana',
                    url: 'https://www.ifpi.edu.br',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Botão de logout ──────────────────────────────────────
              // Exibe diálogo de confirmação antes de deslogar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Diálogo de confirmação (padrão consistente com outras telas)
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Sair da conta'),
                        content: const Text(
                          'Deseja sair da conta e voltar à tela de login?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.emergency,
                            ),
                            child: const Text(
                              'Sair',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return; // usuário cancelou

                    // Desloga: limpa Firebase Auth + cache Hive
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      // Remove toda a pilha de navegação → LoginPage
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.emergency),
                    foregroundColor: AppColors.emergency,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Sair da conta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Rodapé: versão + crédito ─────────────────────────────
              Text(
                'v${AppConstants.appVersion} • ${AppConstants.ifpiCredit}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Seção com título ──────────────────────────────────────────────────────────

/// Seção com título colorido e container branco com sombra.
///
/// Agrupa múltiplos tiles relacionados visualmente.
class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção em verde primário
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
        ),
        // Container que envolve todos os tiles da seção
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.shadow, blurRadius: 8),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Tile informativo ──────────────────────────────────────────────────────────

/// Linha não clicável com ícone, título e subtítulo.
/// Usada para exibir informações estáticas do projeto.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de telefone ──────────────────────────────────────────────────────────

/// Linha clicável que discam para o número via url_launcher.
///
/// Exibe: ícone colorido, nome do serviço, número, botão "LIGAR".
/// Ao tocar, abre o discador nativo com o número pré-preenchido.
class _PhoneTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String phone;
  final Color iconColor;

  const _PhoneTile({
    required this.icon,
    required this.title,
    required this.phone,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Esquema 'tel:' abre o discador nativo do dispositivo
        final uri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            // Botão "LIGAR" com destaque visual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LIGAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de link externo ──────────────────────────────────────────────────────

/// Linha clicável que abre uma URL no navegador externo.
///
/// Exibe: ícone, título e seta de "abrir externamente".
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            // Ícone padrão "abrir em nova janela"
            const Icon(Icons.open_in_new,
                size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
