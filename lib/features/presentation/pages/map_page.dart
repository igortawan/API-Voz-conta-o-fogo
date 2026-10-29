// ============================================================================
// map_page.dart
// ----------------------------------------------------------------------------
// Tela do mapa de focos de incêndio — 2ª aba da NavigationPage.
//
// Tecnologia:
//   • flutter_map (OpenStreetMap) — mapa interativo open-source sem chave de API
//   • latlong2 — tipos de coordenadas (LatLng) compatíveis com flutter_map
//
// Camadas do mapa:
//   1. TileLayer    — tiles do OpenStreetMap (https://tile.openstreetmap.org)
//   2. MarkerLayer  — pinos coloridos representando denúncias do usuário logado
//
// Cor dos pinos:
//   • Vermelho  — fogo nível "Urgente" (fireLevelUrgent)
//   • Laranja   — fogo próximo a residência (fireLevelNearHome por riskLevel)
//   • Verde     — demais ocorrências florestais
//
// Interatividade:
//   • Toque em um pino → abre [_ReportDetailCard] na parte inferior do mapa
//   • Toque fora de pinos → fecha o card de detalhes
//   • Botão "Minha localização" → recentraliza o mapa no ponto padrão
//   • Link "INPE →" no cabeçalho → abre o portal de queimadas no navegador
//
// Centro padrão: AppConstants.defaultLat/defaultLng (Paulistana/PI)
// Zoom padrão:   AppConstants.defaultZoom
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/presentation/controllers/admin_controller.dart';
import '../../report/data/models/report_model.dart';

/// Tela de mapa interativo com marcadores das denúncias do usuário.
///
/// Usa [ConsumerStatefulWidget] para:
///   • Controlar o estado do marcador selecionado (_selectedReport)
///   • Acessar o MapController para recentalizar programaticamente
///   • Assistir [userReportsProvider] via ref.watch
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  /// Controlador do mapa para navegar programaticamente (zoom, center).
  final _mapController = MapController();

  /// Denúncia selecionada ao tocar em um pino. null = nenhuma selecionada.
  ReportModel? _selectedReport;

  /// Centro inicial do mapa — coordenadas de Paulistana/PI.
  static const _initialCenter = LatLng(
    AppConstants.defaultLat,
    AppConstants.defaultLng,
  );

  /// Constrói a lista de [Marker] a partir das denúncias carregadas.
  ///
  /// Cada marker é um ícone colorido baseado no nível de urgência:
  ///   • Urgente → vermelho
  ///   • Próximo a residência → laranja (detectado pelo riskLevel)
  ///   • Outros → verde (florestal / pequeno)
  List<Marker> _buildMarkers(List<ReportModel> reports) {
    return reports.map((r) {
      final isUrgent = r.fireLevel == AppConstants.fireLevelUrgent;
      final isNearHome = r.riskLevel == AppConstants.fireLevelNearHome;
      final color = isUrgent
          ? Colors.red
          : isNearHome
              ? Colors.orange
              : AppColors.primary;

      return Marker(
        point: LatLng(r.latitude, r.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          // Toque no marcador → seleciona a denúncia e exibe o card
          onTap: () => setState(() => _selectedReport = r),
          child: Icon(Icons.location_pin, color: color, size: 36),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Mostra TODAS as denúncias ativas da região (não só do usuário logado).
    // Denúncias rejeitadas são filtradas — apenas focos reais aparecem no mapa.
    final reportsAsync = ref.watch(allReportsProvider).whenData(
          (all) => all
              .where((r) => r.status != AppConstants.statusRejected)
              .toList(),
        );

    return Scaffold(
      body: Stack(
        children: [
          // ── Camada base: mapa OpenStreetMap ──────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: AppConstants.defaultZoom,
              // Toque fora de marcadores → desseleciona o card de detalhes
              onTap: (_, __) => setState(() => _selectedReport = null),
            ),
            children: [
              // Tiles do OpenStreetMap (gratuitos, sem API key)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.voz_contra_o_fogo',
              ),
              // Camada de marcadores — só exibe quando os dados estão carregados
              reportsAsync.when(
                data: (reports) => MarkerLayer(markers: _buildMarkers(reports)),
                loading: () => const MarkerLayer(markers: []), // sem marcadores durante loading
                error: (_, __) => const MarkerLayer(markers: []), // sem marcadores em caso de erro
              ),
            ],
          ),

          // ── Barra de título sobreposta ao mapa ───────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Focos Ativos — Paulistana/PI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Link direto para o portal INPE de queimadas
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(
                              'https://terrabrasilis.dpi.inpe.br/queimadas/bdqueimadas/');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                        child: const Text(
                          'INPE →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Legenda de cores dos marcadores ──────────────────────────
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.shadow, blurRadius: 8),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: Colors.red, label: 'Urgente'),
                  SizedBox(height: 6),
                  _LegendItem(color: Colors.orange, label: 'Residência'),
                  SizedBox(height: 6),
                  _LegendItem(color: AppColors.primary, label: 'Florestal'),
                ],
              ),
            ),
          ),

          // ── Botão "recentalizar" no ponto padrão ─────────────────────
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'location_btn',
              backgroundColor: Colors.white,
              onPressed: () {
                // Move o mapa de volta ao centro padrão com o zoom inicial
                _mapController.move(
                    _initialCenter, AppConstants.defaultZoom);
              },
              child:
                  const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // ── Card de detalhes da denúncia selecionada ─────────────────
          // Exibido somente quando um marcador está selecionado
          if (_selectedReport != null)
            Positioned(
              bottom: 90,
              left: 16,
              right: 72, // folga para não cobrir o FAB de localização
              child: _ReportDetailCard(
                report: _selectedReport!,
                onClose: () => setState(() => _selectedReport = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item da legenda ───────────────────────────────────────────────────────────

/// Linha da legenda: círculo colorido + label textual.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ── Card de detalhes do marcador selecionado ──────────────────────────────────

/// Card flutuante sobre o mapa exibindo resumo da denúncia selecionada.
///
/// Exibe: nível do fogo, descrição (2 linhas), badges de fumaça e status.
/// Botão X fecha o card sem navegar.
class _ReportDetailCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onClose;

  const _ReportDetailCard({required this.report, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMedium, blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: nível do fogo + fechar ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.fireLevel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.textLight),
              ),
            ],
          ),
          // ── Descrição (se disponível) ───────────────────────────────
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
            ),
          ],
          const SizedBox(height: 8),
          // ── Badges: fumaça + status ─────────────────────────────────
          Row(
            children: [
              _badge(report.smokeLevel, Colors.grey),
              const SizedBox(width: 8),
              _badge(report.status, AppColors.statusSent),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge colorido com texto e fundo semitransparente.
  Widget _badge(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      );
}
