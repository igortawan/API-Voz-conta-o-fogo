// ============================================================================
// home_page.dart
// ----------------------------------------------------------------------------
// Tela principal do cidadão (1ª aba da NavigationPage — índice 0).
//
// Composição visual (de cima para baixo):
//   1. [_Header]       — avatar clicável (popup logout) + nome + sino de alertas
//   2. [_Greeting]     — texto "Como podemos ajudar hoje?"
//   3. [_DenunciaCard] — card principal verde que navega para ReportFirePage
//   4. [_ActionsGrid]  — grid 2×1 com atalhos "Minhas Denúncias" e "Prevenção"
//   5. [_RiskCard]     — índice de risco de incêndio com barra de progresso
//   6. [_EmergencyCard]— banner vermelho com botão "LIGAR 193"
//   7. [_InfoCard]     — card com imagem de natureza e link para guia do INPE
//
// Acesso ao nome do usuário:
//   • Função privada [_getUserFirstName()] lê o displayName ou email do
//     Firebase Auth diretamente (sem provider Riverpod) pois é somente leitura
//     e não precisa de reatividade após o login inicial.
//
// Notificações:
//   • O sino do _Header observa [unreadCountProvider] (de notifications_page.dart)
//     e exibe um badge vermelho com a contagem de não lidas.
//   • Consumer aninhado no sino para minimizar rebuilds da árvore.
// ============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../report/presentation/controllers/report_controller.dart';
import 'auth/login.page.dart';
import 'citizen_stats_page.dart';
import 'my_reports_page.dart';
import 'citizen_alerts_page.dart';
import 'notifications_page.dart';
import 'prevention_page.dart';
import 'report_fire_page.dart';

/// Tela principal do usuário cidadão — 1ª aba da NavigationPage.
///
/// Usa [ConsumerWidget] para ter acesso ao Riverpod (ref) no _Header.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(authStateProvider);
    final user = _getUserFirstName(appUser);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _Header(userName: user),
            const SizedBox(height: 28),
            _Greeting(userName: user),
            const SizedBox(height: 28),
            const _DenunciaCard(),
            const SizedBox(height: 20),
            const _ActionsGrid(),
            const SizedBox(height: 20),
            const _RiskCard(),
            const SizedBox(height: 20),
            const _EmergencyCard(),
            const SizedBox(height: 20),
            const _InfoCard(),
            const SizedBox(height: 100), // espaço para o FAB flutuante
          ],
        ),
      ),
    );
  }
}

// ── Helper de nome ────────────────────────────────────────────────────────────

/// Retorna o primeiro nome do usuário logado para saudação na home.
///
/// Prioridade de busca:
///   1. displayName (campo do Firebase Auth) → pega somente o primeiro nome
///   2. email → pega a parte antes do '@'
///   3. 'Cidadão' → fallback para usuários anônimos ou sem dados
///
/// Usa try/catch amplo para garantir que um erro inesperado não quebre a UI.
String _getUserFirstName(dynamic appUser) {
  try {
    if (appUser?.displayName != null && (appUser!.displayName as String).isNotEmpty) {
      return (appUser.displayName as String).split(' ').first;
    }
    if (appUser?.email != null) return (appUser!.email as String).split('@').first;
    return 'Cidadão';
  } catch (_) {
    return 'Cidadão';
  }
}

// ── Cabeçalho ─────────────────────────────────────────────────────────────────

/// Cabeçalho com avatar/nome do usuário à esquerda e sino à direita.
///
/// Avatar: abre PopupMenu com opção de logout.
/// Sino: abre NotificationsPage; exibe badge vermelho se houver não lidas.
class _Header extends ConsumerWidget {
  final String userName;
  const _Header({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Avatar + nome ──────────────────────────────────────────────
        Row(
          children: [
            // Avatar circular que abre popup de logout
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 10),
                      Text('Sair'),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            // Nome e label "BEM-VINDO"
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEM-VINDO',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Sino de notificações com badge ────────────────────────────
        // Consumer aninhado para que apenas o badge rebuilde quando o contador muda
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: Consumer(
            builder: (_, ref, __) {
              final unread = ref.watch(unreadCountProvider);
              final count = unread.valueOrNull ?? 0;
              return Stack(
                children: [
                  // Ícone do sino
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: AppColors.primary),
                  ),
                  // Badge vermelho (visível apenas se count > 0)
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.emergency,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Saudação ──────────────────────────────────────────────────────────────────

/// Texto de saudação com "Como podemos" em preto e "ajudar hoje?" em verde.
class _Greeting extends StatelessWidget {
  final String userName;
  const _Greeting({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como podemos',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const Text(
          'ajudar hoje?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ── Card principal de denúncia ────────────────────────────────────────────────

/// Card verde com gradiente — ação principal da home.
///
/// Toque navega para [ReportFirePage] via Navigator.push.
/// Gradiente linear de #1B7A1B (esquerda-topo) para #2E7D32 (direita-baixo).
class _DenunciaCard extends StatelessWidget {
  const _DenunciaCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportFirePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B7A1B), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone de fogo em container arredondado semitransparente
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Denunciar Incêndio',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reporte focos de incêndio agora para proteger a Caatinga e comunidades.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Grid de ações rápidas ─────────────────────────────────────────────────────

/// Grade com 3 atalhos: "Minhas Denúncias", "Prevenção" e "Estatísticas".
///
/// Layout: 2 cards lado a lado na primeira linha + 1 card largo na segunda.
class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.history_rounded,
                title: 'Minhas\nDenúncias',
                subtitle: 'Acompanhe seus envios',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyReportsPage()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                icon: Icons.eco_rounded,
                title: 'Prevenção',
                subtitle: 'Dicas e cuidados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PreventionPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.bar_chart_rounded,
                title: 'Estatísticas',
                subtitle: 'Resumo das suas denúncias',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenStatsPage()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                icon: Icons.campaign_rounded,
                title: 'Alertas',
                subtitle: 'Avisos das autoridades',
                color: const Color(0xFFE65100),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenAlertsPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card de ação individual do grid — ícone + título + subtítulo.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de risco de incêndio ─────────────────────────────────────────────────

/// Card com índice de risco calculado a partir das denúncias ativas na região.
///
/// Fórmula: contagem de denúncias ativas dos últimos 30 dias mapeada para
/// nível de risco (Baixo → Moderado → Alto → Crítico).
/// Usa [localReportsProvider] (cidadão) para cálculo mesmo sem internet.
class _RiskCard extends ConsumerWidget {
  const _RiskCard();

  /// Calcula o nível de risco baseado no total de denúncias ativas.
  static (String label, Color color, double value) _calcRisk(int activeCount) {
    if (activeCount == 0) return ('Baixo',   Colors.green,        0.15);
    if (activeCount <= 2) return ('Moderado', AppColors.statusSent, 0.40);
    if (activeCount <= 5) return ('Alto',     AppColors.warning,   0.72);
    return               ('Crítico',  AppColors.emergency,  1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Conta denúncias ativas (não atendidas/rejeitadas) para estimar risco
    final reports = ref.watch(localReportsProvider);
    final active = reports
        .where((r) =>
            r.status != AppConstants.statusAttended &&
            r.status != AppConstants.statusRejected)
        .length;

    final (label, color, value) = _calcRisk(active);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Índice de risco de incêndio — Região Paulistana/PI',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baseado em $active denúncia(s) ativa(s)\nno seu histórico local',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            child: const Text(
              'Ver dados INPE →',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de emergência ────────────────────────────────────────────────────────

/// Banner vermelho com botão direto para ligar ao Corpo de Bombeiros (193).
///
/// Cor de fundo: [AppColors.emergencyLight] (vermelho muito claro).
/// Borda: vermelho com 20% de opacidade.
/// Botão "LIGAR 193" abre o discador nativo.
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.emergencyLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.emergency.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicador piscante + texto
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.emergency,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Emergência Nacional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          // Botão vermelho "LIGAR 193"
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:${AppConstants.phoneFireDepartment}');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emergency,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LIGAR 193',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card informativo com imagem ───────────────────────────────────────────────

/// Card com imagem de natureza (Unsplash) e texto sobre identificação de riscos.
///
/// Imagem carregada via [CachedNetworkImage] com:
///   • placeholder: ícone de imagem (sem conexão ou carregando)
///   • errorWidget: ícone de floresta (imagem indisponível)
/// Link "Ler guia completo →" redireciona para o portal de queimadas do INPE.
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias, // necessário para o ClipRRect interno funcionar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem de capa com cantos arredondados no topo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              // Placeholder: exibido enquanto a imagem carrega ou offline
              placeholder: (_, __) => Container(
                height: 130,
                color: AppColors.primarySoft.withValues(alpha: 0.15),
                child: const Center(
                  child: Icon(Icons.image, color: AppColors.textLight, size: 36),
                ),
              ),
              // Fallback: exibido se a URL falhar ou não houver conexão
              errorWidget: (_, __, ___) => Container(
                height: 130,
                color: AppColors.primarySoft.withValues(alpha: 0.15),
                child: const Center(
                  child: Icon(Icons.forest, color: AppColors.primarySoft, size: 44),
                ),
              ),
            ),
          ),
          // Conteúdo textual abaixo da imagem
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Como identificar riscos precoces',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aprenda a notar sinais de fumaça atípica e condições de seca severa na Caatinga.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Link externo para o INPE
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: const Text(
                    'Ler guia completo →',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
