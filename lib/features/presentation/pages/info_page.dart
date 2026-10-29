// ============================================================================
// info_page.dart
// ----------------------------------------------------------------------------
// Tela "Informações Preventivas" — conteúdo educativo sobre prevenção de
// incêndios na Caatinga, com busca, guia de orientações e telefones de
// emergência.
//
// Estrutura visual (de cima para baixo):
//   • Cabeçalho com título e campo de busca
//   • _AlertCard  — card laranja de alerta ao período de seca (visível quando
//                   a busca está vazia)
//   • Guia de Prevenção — lista filtrável de _InfoCard (6 itens)
//   • Telefones Úteis  — grade 2×2 de _PhoneCard + 1 _IbamaCard (filtráveis)
//
// Busca:
//   • Filtra os _InfoCard comparando title e subtitle (case-insensitive)
//   • Quando a busca não está vazia, o _AlertCard e os telefones são ocultados
//     para reduzir ruído visual e focar no resultado
//
// URL launching:
//   • Todos os links externos usam `url_launcher` com `canLaunchUrl` como
//     verificação antes de `launchUrl`, seguindo a API recomendada pelo pacote.
//   • Links `tel:` abrem o discador nativo do dispositivo.
//
// CORREÇÃO (v1.1):
//   • Renomeado `InforPage` → `InfoPage` (era um typo, a classe não é usada
//     externamente então a renomeação é segura).
//   • Substituído `.withOpacity()` → `.withValues(alpha:)` (API não depreciada).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

// ── Página principal ──────────────────────────────────────────────────────────

/// Tela de informações preventivas sobre incêndios na Caatinga.
///
/// Exibe orientações educativas, telefones de emergência e links externos para
/// dados do INPE. Possui campo de busca que filtra as orientações em tempo real.
///
/// **Nota:** esta tela não aparece no [NavigationPage] (foi substituída por
/// [PreventionPage] na navegação principal), mas pode ser acessada via push
/// em contextos específicos.
class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

/// Estado interno de [InfoPage].
///
/// Gerencia:
///   • [_searchController] — controlador do campo de busca (dispose no encerramento)
///   • [_searchQuery]      — texto atual da busca em minúsculas (para comparação)
class _InfoPageState extends State<InfoPage> {
  /// Controlador do TextField de busca. Deve ser descartado no [dispose].
  final _searchController = TextEditingController();

  /// Texto atual do campo de busca, convertido para minúsculas.
  /// Usado para filtrar [_preventionItems] sem distinção de maiúsculas/minúsculas.
  String _searchQuery = '';

  @override
  void dispose() {
    // Libera o controlador para evitar vazamento de memória
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabeçalho: título + campo de busca ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Preventivas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo de busca — filtra orientações por título e subtítulo
                  TextField(
                    controller: _searchController,
                    // Atualiza _searchQuery em tempo real a cada caractere digitado
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar orientações...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            // ── Corpo rolável ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Card de alerta de seca — oculto durante a busca para não
                    // poluir a lista de resultados filtrados
                    if (_searchQuery.isEmpty) ...[
                      _AlertCard(),
                      const SizedBox(height: 24),
                    ],

                    // ── Guia de Prevenção ─────────────────────────────────────
                    const Text(
                      'Guia de Prevenção',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Filtra os itens cujo title OU subtitle contém a busca.
                    // Se _searchQuery for vazio, todos os itens são exibidos.
                    ..._preventionItems
                        .where((item) =>
                            _searchQuery.isEmpty ||
                            item.title.toLowerCase().contains(_searchQuery) ||
                            item.subtitle.toLowerCase().contains(_searchQuery))
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InfoCard(
                              icon: item.icon,
                              title: item.title,
                              subtitle: item.subtitle,
                              url: item.url,
                            ),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // ── Telefones Úteis ───────────────────────────────────────
                    // Exibido quando a busca está vazia ou contém termos
                    // relacionados a telefone/emergência
                    if (_searchQuery.isEmpty ||
                        'telefone emergência bombeiros'.contains(_searchQuery)) ...[
                      const Text(
                        'Telefones Úteis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Linha 1: Bombeiros + Defesa Civil
                      Row(
                        children: [
                          Expanded(
                            child: _PhoneCard(
                              icon: Icons.fire_truck,
                              number: AppConstants.phoneFireDepartment,
                              label: 'Bombeiros',
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _PhoneCard(
                              icon: Icons.security,
                              number: AppConstants.phoneCivilDefense,
                              label: 'Defesa Civil',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Linha 2: Polícia Militar + SAMU
                      Row(
                        children: [
                          Expanded(
                            child: _PhoneCard(
                              icon: Icons.local_police,
                              number: AppConstants.phoneMilitaryPolice,
                              label: 'Polícia Militar',
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _PhoneCard(
                              icon: Icons.medical_services,
                              number: AppConstants.phoneSamu,
                              label: 'SAMU',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Card especial do IBAMA (Linha Verde) — largura total
                      _IbamaCard(),
                    ],

                    // Espaçamento extra para não ficar atrás do BottomAppBar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dados — itens do guia de prevenção ────────────────────────────────────────

/// Modelo de dado imutável para um item do guia de prevenção.
///
/// Cada item possui:
///   • [icon]     — ícone visual do Material Design
///   • [title]    — título curto exibido em negrito
///   • [subtitle] — descrição resumida (2 linhas max)
///   • [url]      — link externo opcional; se preenchido, o card torna-se tappable
class _PreventionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? url; // null = card informativo sem link externo

  const _PreventionItem(this.icon, this.title, this.subtitle, [this.url]);
}

/// Lista estática de orientações preventivas exibidas no Guia de Prevenção.
///
/// Os itens com [url] apontam para o portal de queimadas do INPE, que oferece
/// dados satelitais em tempo real sobre focos de incêndio no Brasil.
///
/// Itens sem [url] apresentam apenas texto informativo local (sem link externo).
final _preventionItems = [
  const _PreventionItem(
    Icons.eco,
    'Como prevenir queimadas',
    'Dicas essenciais sobre descarte de lixo, limpeza de terrenos e uso do fogo na Caatinga.',
    'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/',
  ),
  const _PreventionItem(
    Icons.warning_amber,
    'Em caso de incêndio',
    'Protocolos de segurança, rotas de fuga e como acionar os Bombeiros Civis de Paulistana.',
    // sem URL — informação local sem link externo
  ),
  const _PreventionItem(
    Icons.forest,
    'Manutenção de Aceiros',
    'Saiba como proteger sua propriedade rural criando barreiras naturais contra o fogo.',
    // sem URL
  ),
  const _PreventionItem(
    Icons.wb_sunny,
    'Períodos de Seca — Caatinga',
    'Como o clima semiárido do Piauí favorece incêndios. Dados históricos e previsão.',
    'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/',
  ),
  const _PreventionItem(
    Icons.smoke_free,
    'Queimadas Ilegais',
    'Penalidades previstas na Lei Federal 9.605/1998 e Lei Municipal 180/2022 de Paulistana.',
    // sem URL
  ),
  const _PreventionItem(
    Icons.satellite_alt,
    'Monitoramento pelo INPE',
    'Dados de satélite em tempo real sobre focos de incêndio no Piauí e no Brasil.',
    'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/',
  ),
];

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Card de alerta laranja destacando o período de seca.
///
/// Exibido no topo da tela apenas quando a busca está vazia.
/// Contém:
///   • Ícone de sol
///   • Título em maiúsculas com badge "ALTO RISCO"
///   • Texto explicativo sobre o risco no semiárido piauiense
///   • Botão "Ver Recomendações →" que abre o portal de queimadas do INPE
class _AlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        // Borda laranja translúcida para reforçar o contexto de alerta
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Ícone de sol com fundo laranja translúcido
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny, color: AppColors.warning, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + badge de risco na mesma linha
                Row(
                  children: [
                    const Text(
                      'ALERTA: PERÍODO DE SECA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.warning,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge vermelho "ALTO RISCO"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emergency,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ALTO RISCO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Texto informativo sobre o risco no semiárido
                const Text(
                  'As condições climáticas do semiárido piauiense favorecem a propagação de focos de incêndio. Evite qualquer tipo de queimada.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),

                // Botão de ação — abre o portal do INPE no navegador
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/');
                    // canLaunchUrl verifica se o dispositivo pode abrir a URL
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ver Recomendações →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

/// Card tappable para um item do guia de prevenção.
///
/// Se [url] for fornecido, o toque abre o link externo no navegador padrão.
/// Se [url] for null, o card é apenas visual (sem interação de toque).
///
/// Exibe: ícone com fundo primário translúcido, título, subtítulo e seta →
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? url; // null = card sem ação de toque

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap é null quando url é null → GestureDetector não responde ao toque
      onTap: url != null
          ? () async {
              final uri = Uri.parse(url!);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Ícone com fundo primário translúcido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),

            // Texto: título em negrito + subtítulo em cinza
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),

            // Seta indicativa de ação (sempre visível, mesmo sem url)
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// Card de telefone de emergência.
///
/// Ao tocar, abre o discador nativo com o número pré-preenchido via `tel:`.
/// Exibe: ícone com a [color] do serviço, [number], [label] e botão "LIGAR".
class _PhoneCard extends StatelessWidget {
  final IconData icon;
  final String number; // número de telefone (ex.: '193')
  final String label;  // nome do serviço (ex.: 'Bombeiros')
  final Color color;   // cor temática do serviço

  const _PhoneCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Abre o discador nativo com o número pré-preenchido
      onTap: () async {
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
        ),
        child: Column(
          children: [
            // Ícone do serviço na cor temática
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),

            // Número em destaque (fonte grande)
            Text(
              number,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // Nome do serviço
            Text(label,
                style:
                    const TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 10),

            // Botão "LIGAR" visual (a ação real está no GestureDetector pai)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LIGAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card especial do IBAMA (Linha Verde).
///
/// Layout diferente dos demais _PhoneCard: usa layout horizontal (Row) com
/// ícone à esquerda e seta de "abrir" à direita.
/// Ao tocar, liga para [AppConstants.phoneIbama] via `tel:`.
class _IbamaCard extends StatelessWidget {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Ícone de ligação com fundo primário translúcido
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),

                // Texto: nome + número da Linha Verde
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IBAMA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Linha Verde: 0800 061 8080',
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ],
            ),

            // Ícone indicativo de que abre ação externa (discador)
            const Icon(Icons.open_in_new, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
