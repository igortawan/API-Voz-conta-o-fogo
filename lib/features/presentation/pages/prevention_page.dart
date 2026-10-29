// ============================================================================
// prevention_page.dart
// ----------------------------------------------------------------------------
// Tela de Prevenção de Incêndios — 3ª aba da NavigationPage.
//
// Estrutura:
//   • NestedScrollView + SliverAppBar (expandedHeight: 160) com gradiente verde
//   • TabBar com 3 abas: PREVENÇÃO | EMERGÊNCIA | LEGISLAÇÃO
//   • TabBarView com um ListView por aba
//
// Parâmetros do construtor:
//   • [isTab] = true  → sem botão de voltar (acessado pela barra de navegação)
//   • [isTab] = false → com botão de voltar (acessado via Navigator.push da home)
//
// ── ABA 1: PREVENÇÃO ──────────────────────────────────────────────────────────
//   • [_AlertBanner]  — alerta sazonal laranja com badge "ALTO RISCO"
//   • 6 [_ExpandableTip] — dicas expansíveis via ExpansionTile:
//       1. Queimadas ilegais (vermelho)
//       2. Descarte de lixo (laranja)
//       3. Criação de aceiros (verde)
//       4. Monitoramento INPE (azul) — tem link de ação para o portal
//       5. Período crítico da Caatinga (âmbar)
//       6. Educação ambiental comunitária (verde claro)
//   • [_InpeButton] — card azul que abre o portal de queimadas do INPE
//
// ── ABA 2: EMERGÊNCIA ─────────────────────────────────────────────────────────
//   • Banner vermelho "Em caso de incêndio"
//   • 5 [_EmergencyStep] — passos numerados do que fazer
//   • Grade 2×2 com [_PhoneCard] — Bombeiros (193), Defesa Civil (199),
//       Polícia Militar (190), SAMU (192)
//   • [_IbamaCard] — IBAMA Linha Verde 0800 061 8080 (gratuito 24h)
//
// ── ABA 3: LEGISLAÇÃO ─────────────────────────────────────────────────────────
//   • 3 [_LawCard] — leis federais (9.605/98, 12.651/12, CONAMA 011/88)
//   • Lei Municipal 180/2022 — proibição de queimadas em Paulistana
//   • [_IbamaCard] com botão para ligar
//
// Widgets compartilhados entre abas:
//   [_SectionTitle], [_AlertBanner], [_RiskBadge], [_ExpandableTip],
//   [_InpeButton], [_EmergencyStep], [_PhoneCard], [_IbamaCard],
//   [_Article] (dados), [_LawCard]
// ============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Página de Prevenção completa com 3 abas: Prevenção / Emergência / Legislação.
///
/// [isTab] = true quando usada como aba do BottomNav (sem botão de voltar).
/// [isTab] = false quando empurrada via Navigator.push (AppBar com voltar).
class PreventionPage extends StatefulWidget {
  final bool isTab;
  const PreventionPage({super.key, this.isTab = false});

  @override
  State<PreventionPage> createState() => _PreventionPageState();
}

class _PreventionPageState extends State<PreventionPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this); // 3 abas
  }

  @override
  void dispose() {
    _tab.dispose(); // libera recursos do TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        // NestedScrollView permite que o SliverAppBar colapse ao rolar o ListView
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,      // altura máxima expandida do header
              pinned: true,              // header fica fixo no topo ao rolar
              floating: false,
              automaticallyImplyLeading: false, // controle manual via [isTab]
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              // Botão de voltar: visível apenas quando acessado via Navigator.push
              leading: widget.isTab
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
              // Header expandido com gradiente e ícone
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B7A1B), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        widget.isTab ? 18 : 52, // isTab=true → sem espaço para AppBar
                        20,
                        48, // espaço para as abas abaixo
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.eco,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Prevenção de Incêndios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Caatinga · Paulistana, PI',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Abas fixadas na parte inferior do SliverAppBar
              bottom: TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: 'PREVENÇÃO'),
                  Tab(text: 'EMERGÊNCIA'),
                  Tab(text: 'LEGISLAÇÃO'),
                ],
              ),
            ),
          ];
        },
        // Conteúdo das 3 abas
        body: TabBarView(
          controller: _tab,
          children: const [
            _PreventionTab(),
            _EmergencyTab(),
            _LegislationTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA 1 — PREVENÇÃO
// ─────────────────────────────────────────────────────────────────────────────

/// Conteúdo da aba "Prevenção": alerta sazonal + 6 dicas expansíveis + botão INPE.
class _PreventionTab extends StatelessWidget {
  const _PreventionTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        // Banner de alerta laranja com badge "ALTO RISCO"
        const _AlertBanner(),
        const SizedBox(height: 20),
        const _SectionTitle(icon: Icons.lightbulb_outline, title: 'Dicas de Prevenção'),
        const SizedBox(height: 12),

        // ── Dica 1: Queimadas ilegais ──────────────────────────────────
        const _ExpandableTip(
          icon: Icons.gpp_bad_outlined,
          iconColor: Color(0xFFD32F2F),
          title: 'Queimadas são crime ambiental',
          summary: 'Não realize queimadas sem autorização do órgão ambiental.',
          details:
              'Queimadas não autorizadas são crime ambiental previsto na Lei Federal '
              '9.605/1998, com pena de até 4 anos de reclusão e multa. No Piauí, a '
              'seca severa faz o fogo se alastrar em minutos destruindo hectares de Caatinga.\n\n'
              '• Contate o IBAMA antes de qualquer manejo com fogo\n'
              '• Denuncie pelo Linha Verde gratuito: 0800 061 8080\n'
              '• Registre a ocorrência pelo app com foto e localização',
        ),
        const SizedBox(height: 10),

        // ── Dica 2: Descarte de lixo ───────────────────────────────────
        const _ExpandableTip(
          icon: Icons.delete_outline,
          iconColor: Color(0xFFF57C00),
          title: 'Descarte correto do lixo',
          summary: 'Garrafas, cigarros e resíduos podem causar incêndios em dias secos.',
          details:
              'Materiais aparentemente inofensivos podem iniciar incêndios na Caatinga:\n\n'
              '• Garrafas de vidro concentram luz solar como lupa — nunca abandone no campo\n'
              '• Bitucas de cigarro devem ser completamente apagadas antes do descarte\n'
              '• Nunca jogue lixo em terrenos baldios, margens de estradas ou áreas verdes\n'
              '• Use lixeiras adequadas ou leve o lixo consigo ao sair de áreas naturais',
        ),
        const SizedBox(height: 10),

        // ── Dica 3: Criação de aceiros ─────────────────────────────────
        const _ExpandableTip(
          icon: Icons.forest,
          iconColor: AppColors.primarySoft,
          title: 'Criação de Aceiros',
          summary: 'Barreiras de vegetação limpa que protegem propriedades contra o fogo.',
          details:
              'Aceiros são faixas limpas de vegetação ao redor de propriedades que '
              'impedem a propagação do fogo:\n\n'
              '• Largura mínima recomendada: 6 a 10 metros\n'
              '• Remova toda matéria orgânica seca (folhas, galhos, capim)\n'
              '• Mantenha limpo durante todo o período de seca (junho a novembro)\n'
              '• Faça a manutenção antes de junho, antes da estação seca começar\n'
              '• Consulte a Defesa Civil (199) ou IBAMA para orientações específicas',
        ),
        const SizedBox(height: 10),

        // ── Dica 4: Monitoramento INPE (com link de ação) ─────────────
        const _ExpandableTip(
          icon: Icons.satellite_alt,
          iconColor: Color(0xFF1565C0),
          title: 'Monitoramento pelo INPE',
          summary: 'Acompanhe focos de incêndio em tempo real via satélite.',
          details:
              'O Instituto Nacional de Pesquisas Espaciais (INPE) oferece dados gratuitos:\n\n'
              '• Atualização a cada hora via satélite\n'
              '• Mapa interativo em terrabrasilis.dpi.inpe.br\n'
              '• Alertas por e-mail para regiões cadastradas\n'
              '• Dados históricos desde 1998\n'
              '• Cobertura de todo o território nacional com múltiplos satélites',
          actionLabel: 'Abrir portal INPE →',
          actionUrl: 'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/',
        ),
        const SizedBox(height: 10),

        // ── Dica 5: Período crítico da Caatinga ────────────────────────
        const _ExpandableTip(
          icon: Icons.wb_sunny_outlined,
          iconColor: Color(0xFFF9A825),
          title: 'Período crítico — Caatinga',
          summary: 'Seca severa de junho a novembro aumenta drasticamente o risco.',
          details:
              'O bioma Caatinga é altamente vulnerável a incêndios na estação seca:\n\n'
              '• Período crítico: junho a novembro\n'
              '• Umidade relativa pode cair abaixo de 15% no semiárido piauiense\n'
              '• Vegetação ressecada entra em combustão com facilidade\n'
              '• Ventos fortes podem propagar o fogo a mais de 10 km/h\n'
              '• Evite qualquer atividade com fogo nesse período\n'
              '• Monitore o INPE e os alertas do Corpo de Bombeiros regularmente',
        ),
        const SizedBox(height: 10),

        // ── Dica 6: Educação ambiental ─────────────────────────────────
        const _ExpandableTip(
          icon: Icons.people_outline,
          iconColor: AppColors.primaryGlow,
          title: 'Educação ambiental comunitária',
          summary: 'Compartilhe e conscientize sua comunidade sobre o perigo do fogo.',
          details:
              'A prevenção começa na própria comunidade:\n\n'
              '• Explique às crianças o perigo do fogo em áreas abertas e de Caatinga\n'
              '• Compartilhe este guia com vizinhos, família e amigos\n'
              '• Participe de eventos de conscientização ambiental do IFPI e IBAMA\n'
              '• Denuncie comportamentos de risco às autoridades\n'
              '• Apoie iniciativas locais de reflorestamento da Caatinga\n'
              '• Escolas, igrejas e associações são ótimos multiplicadores de informação',
        ),
        const SizedBox(height: 24),

        // Botão azul de acesso rápido ao portal INPE
        _InpeButton(),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA 2 — EMERGÊNCIA
// ─────────────────────────────────────────────────────────────────────────────

/// Conteúdo da aba "Emergência": banner + 5 passos + grade de telefones + IBAMA.
class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        // ── Banner de emergência vermelho ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emergencyLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.emergency.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department,
                    color: AppColors.emergency, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Em caso de incêndio',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.emergency),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aja rapidamente. Cada segundo conta para salvar vidas e o meio ambiente.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const _SectionTitle(
            icon: Icons.format_list_numbered, title: 'O que fazer'),
        const SizedBox(height: 12),

        // ── 5 passos de emergência ─────────────────────────────────────
        const _EmergencyStep(
          number: 1,
          icon: Icons.call,
          title: 'Ligue imediatamente para 193',
          description:
              'Informe sua localização exata, tamanho estimado do foco '
              'e se há pessoas em risco nas proximidades.',
          color: AppColors.emergency,
        ),
        const SizedBox(height: 10),
        const _EmergencyStep(
          number: 2,
          icon: Icons.social_distance,
          title: 'Mantenha distância segura',
          description:
              'Nunca se aproxime de uma área em chamas. O fogo na Caatinga '
              'se alastra muito rapidamente com o vento.',
          color: Color(0xFFE65100),
        ),
        const SizedBox(height: 10),
        const _EmergencyStep(
          number: 3,
          icon: Icons.masks,
          title: 'Proteja-se da fumaça',
          description:
              'A fumaça de queimadas contém gases tóxicos. Cubra boca e nariz '
              'com pano úmido e evacue para área com ar limpo.',
          color: Color(0xFF6D4C41),
        ),
        const SizedBox(height: 10),
        const _EmergencyStep(
          number: 4,
          icon: Icons.camera_alt_outlined,
          title: 'Denuncie pelo aplicativo',
          description:
              'Registre fotos e a localização precisa do incêndio. '
              'Isso ajuda as autoridades a localizar e agir com mais rapidez.',
          color: AppColors.primarySoft,
        ),
        const SizedBox(height: 10),
        const _EmergencyStep(
          number: 5,
          icon: Icons.do_not_disturb_alt_outlined,
          title: 'Aguarde liberação oficial',
          description:
              'Não retorne ao local antes da liberação pelos Bombeiros. '
              'Há risco de reignição e estruturas instáveis.',
          color: Color(0xFF7B1FA2),
        ),

        const SizedBox(height: 24),
        const _SectionTitle(
            icon: Icons.phone_in_talk_outlined,
            title: 'Contatos de Emergência'),
        const SizedBox(height: 12),

        // ── Grade 2×2 de telefones de emergência ──────────────────────
        Row(
          children: [
            Expanded(
              child: _PhoneCard(
                icon: Icons.fire_truck,
                number: AppConstants.phoneFireDepartment,
                label: 'Bombeiros',
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhoneCard(
                icon: Icons.security_outlined,
                number: AppConstants.phoneCivilDefense,
                label: 'Defesa Civil',
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PhoneCard(
                icon: Icons.local_police_outlined,
                number: AppConstants.phoneMilitaryPolice,
                label: 'Polícia Militar',
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhoneCard(
                icon: Icons.medical_services_outlined,
                number: AppConstants.phoneSamu,
                label: 'SAMU',
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // IBAMA Linha Verde (gratuito 24h)
        const _IbamaCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA 3 — LEGISLAÇÃO
// ─────────────────────────────────────────────────────────────────────────────

/// Conteúdo da aba "Legislação": leis federais + lei municipal de Paulistana.
class _LegislationTab extends StatelessWidget {
  const _LegislationTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        // Aviso introdutório sobre a legislação
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.gavel, color: AppColors.primary, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Conheça a legislação brasileira sobre incêndios florestais e a proteção da Caatinga.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const _SectionTitle(
            icon: Icons.article_outlined, title: 'Leis Aplicáveis'),
        const SizedBox(height: 12),

        // ── Lei 9.605/1998 — Crimes Ambientais ────────────────────────
        const _LawCard(
          number: '9.605/1998',
          title: 'Lei de Crimes Ambientais',
          subtitle: 'Principal lei penal ambiental do Brasil',
          color: AppColors.emergency,
          articles: [
            _Article(
              article: 'Art. 38',
              description: 'Destruir ou danificar floresta em área de preservação permanente',
              penalty: '1 a 3 anos de detenção + multa',
            ),
            _Article(
              article: 'Art. 41',
              description: 'Provocar incêndio em mata ou floresta',
              penalty: '2 a 4 anos de reclusão + multa',
            ),
            _Article(
              article: 'Agravante',
              description:
                  'Ação durante período de estiagem, em área de preservação ou de forma dolosa',
              penalty: 'Pena aumentada em até metade',
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Lei 12.651/2012 — Código Florestal ────────────────────────
        const _LawCard(
          number: '12.651/2012',
          title: 'Código Florestal',
          subtitle: 'Regula o uso do fogo em atividades agropastoris',
          color: AppColors.primarySoft,
          articles: [
            _Article(
              article: 'Art. 38',
              description:
                  'Proibição geral do uso do fogo em vegetação nativa ou áreas de preservação',
              penalty: 'Responsabilidade civil, administrativa e penal',
            ),
            _Article(
              article: 'Exceção',
              description:
                  'Queima controlada em atividades agropastoris com autorização prévia do órgão ambiental',
              penalty: 'Exige Autorização de Queima Prescrita (AQP)',
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── CONAMA 011/88 ──────────────────────────────────────────────
        const _LawCard(
          number: 'CONAMA 011/88',
          title: 'Resolução CONAMA',
          subtitle: 'Procedimentos para uso do fogo controlado',
          color: Color(0xFF6D4C41),
          articles: [
            _Article(
              article: 'Definição',
              description:
                  'Regulamenta o uso do fogo em propriedades rurais para fins agrossilvipastoris',
              penalty: 'Exige plano de queima aprovado pelo órgão ambiental',
            ),
            _Article(
              article: 'Responsabilidade',
              description:
                  'O proprietário é responsável por qualquer dano causado pelo fogo, mesmo autorizado',
              penalty: 'Responsabilidade objetiva — sem necessidade de provar culpa',
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle(
            icon: Icons.location_city_outlined,
            title: 'Legislação Municipal — Paulistana/PI'),
        const SizedBox(height: 12),

        // ── Lei Municipal 180/2022 — Paulistana ────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Lei 180/2022',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Proibição de queimadas no Município de Paulistana',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Proíbe qualquer tipo de queimada dentro do município de Paulistana, '
                'independente do período do ano ou finalidade. Multas administrativas '
                'de 1 a 50 salários mínimos, podendo haver enquadramento também na '
                'Lei Federal 9.605/1998.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMedium, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const _IbamaCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPARTILHADOS
// ─────────────────────────────────────────────────────────────────────────────

/// Título de seção com ícone à esquerda.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
      ],
    );
  }
}

/// Banner laranja de alerta sazonal com badge "ALTO RISCO".
class _AlertBanner extends StatelessWidget {
  const _AlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.95),
            const Color(0xFFFF8F00).withValues(alpha: 0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Ícone de sol em fundo semitransparente
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ALERTA SAZONAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    _RiskBadge(), // badge vermelho "ALTO RISCO"
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'As condições do semiárido piauiense favorecem a propagação de focos. '
                  'Evite qualquer tipo de queimada.',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge vermelho com texto "ALTO RISCO".
class _RiskBadge extends StatelessWidget {
  const _RiskBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emergency,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ALTO RISCO',
        style: TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Card expansível com dica de prevenção usando [ExpansionTile].
///
/// Parâmetros:
///   • [icon] / [iconColor] — ícone e cor do container à esquerda
///   • [title] / [summary] — exibidos sempre (fechado)
///   • [details]           — exibido ao expandir
///   • [actionLabel] / [actionUrl] — link opcional após o detalhe
class _ExpandableTip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String summary;
  final String details;
  final String? actionLabel;
  final String? actionUrl;

  const _ExpandableTip({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.summary,
    required this.details,
    this.actionLabel,
    this.actionUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove a linha divisória padrão do ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            summary,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            // Texto detalhado exibido ao expandir
            Text(
              details,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium, height: 1.6),
            ),
            // Link de ação opcional (ex: "Abrir portal INPE →")
            if (actionLabel != null && actionUrl != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(actionUrl!);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botão azul que abre o portal de queimadas do INPE.
class _InpeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri =
            Uri.parse('https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.satellite_alt, color: Color(0xFF0D47A1), size: 26),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INPE — Monitoramento de Queimadas',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                        fontSize: 14),
                  ),
                  Text(
                    'Dados de satélite em tempo real sobre focos no Piauí',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: Color(0xFF0D47A1), size: 18),
          ],
        ),
      ),
    );
  }
}

/// Passo numerado de ação em situação de emergência.
///
/// Exibe: número colorido + ícone + título + descrição detalhada.
class _EmergencyStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _EmergencyStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número do passo em círculo colorido
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de telefone de emergência com ícone, número grande e botão "LIGAR".
///
/// Toque em qualquer lugar do card → abre o discador nativo (tel:número).
class _PhoneCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color color;

  const _PhoneCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(number,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIGAR',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card do IBAMA Linha Verde — canal gratuito de denúncias ambientais 24h.
///
/// Toque → liga para 0800 061 8080.
class _IbamaCard extends StatelessWidget {
  const _IbamaCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:${AppConstants.phoneIbama}');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IBAMA — Linha Verde',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('0800 061 8080 (gratuito 24h)',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 12)),
                  Text('Denúncias de crimes ambientais',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.call, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS DE LEGISLAÇÃO
// ─────────────────────────────────────────────────────────────────────────────

/// Dados de um artigo legal: identificador, descrição e penalidade.
///
/// Classe imutável (const) pois é usada apenas como dado estático.
class _Article {
  final String article;     // ex: "Art. 41"
  final String description; // descrição do delito
  final String penalty;     // pena prevista
  const _Article({
    required this.article,
    required this.description,
    required this.penalty,
  });
}

/// Card de lei com cabeçalho colorido e lista de artigos.
///
/// Layout:
///   • Cabeçalho: badge com número da lei + título + subtítulo + borda lateral colorida
///   • Artigos: lista de [_Article] com badge do artigo, descrição e penalidade (em itálico)
class _LawCard extends StatelessWidget {
  final String number;           // ex: "9.605/1998"
  final String title;            // ex: "Lei de Crimes Ambientais"
  final String subtitle;         // ex: "Principal lei penal ambiental do Brasil"
  final Color color;             // cor temática da lei
  final List<_Article> articles; // artigos relevantes

  const _LawCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da lei com borda lateral colorida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Row(
              children: [
                // Badge com número da lei
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lei $number',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de artigos
          ...articles.map(
            (a) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge do artigo (ex: "Art. 41")
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.article,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.description,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        // Penalidade em itálico
                        Row(
                          children: [
                            const Icon(Icons.gavel,
                                size: 12, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.penalty,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
