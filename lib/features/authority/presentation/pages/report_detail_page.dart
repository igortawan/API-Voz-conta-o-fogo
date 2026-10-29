// ============================================================================
// report_detail_page.dart
// ----------------------------------------------------------------------------
// Tela de detalhe de uma denúncia específica.
//
// Utilização:
//   • AuthorityPage  → readOnly = false (pode alterar status)
//   • AdminPage      → readOnly = true  (somente visualização)
//   • AuthorityNotificationsPage → readOnly = false (via toque no card)
//
// Estrutura da página (SingleChildScrollView):
//   1. Mapa interativo (220px) centrado nas coordenadas da denúncia
//      — InteractiveFlag: pinchZoom | drag (navegação habilitada)
//   2. Seção de metadados:
//      • StatusChip + data de criação
//      • _InfoRow: tipo do fogo, fumaça, risco, coordenadas, endereço
//      • Badge "Anônimo" (quando report.anonymous == true)
//   3. Caixa de descrição (se não vazia)
//   4. Galeria horizontal de fotos com CachedNetworkImage
//      • Toque → abre _PhotoViewer (tela preta com PageView)
//      • Mensagem "Sem fotos" quando report.images está vazio
//   5. _StatusButtons (somente se readOnly == false)
//      — 3 opções: Em Verificação / Resolvida / Rejeitar
//
// Widgets internos:
//   • [_StatusButtons]  — 3 botões de ação para alterar status
//   • [_InfoRow]        — linha de metadado: ícone + label + valor
//   • [_StatusChip]     — pill colorido com ponto e texto do status
//   • [_PhotoViewer]    — galeria fullscreen com PageView + InteractiveViewer
//
// Atualização de status (_StatusButtons._setStatus):
//   1. Chama FirestoreService.updateReportStatus(id, newStatus, uid)
//   2. Exibe SnackBar de sucesso com mensagem de notificação ao usuário
//   3. Fecha a tela (Navigator.pop) para que AuthorityPage atualize a lista
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api/django_report_service.dart';
import '../../../report/data/models/report_model.dart';

// ── Widget principal ──────────────────────────────────────────────────────────

/// Tela de visualização completa de uma denúncia.
///
/// Parâmetros:
///   • [report]   — dados completos da denúncia a exibir
///   • [readOnly] — quando true, oculta os botões de alteração de status
///                  (usado no AdminPage onde o admin apenas consulta)
class ReportDetailPage extends StatelessWidget {
  final ReportModel report;

  /// Quando true, oculta [_StatusButtons] (modo somente leitura do admin).
  final bool readOnly;

  const ReportDetailPage({
    super.key,
    required this.report,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt);
    // Coordenadas para centralizar o mapa
    final reportLocation = LatLng(report.latitude, report.longitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhe da Denúncia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mapa interativo centrado na localização da denúncia ───────
            // Permite pinch-zoom e arrastar para explorar a região
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: reportLocation,
                  initialZoom: 15, // zoom alto para mostrar contexto local
                  interactionOptions: const InteractionOptions(
                    // Permite zoom por pinça e arraste, mas não rotação
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  // Tiles OpenStreetMap (sem API key)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.voz_contra_o_fogo',
                  ),
                  // Marcador vermelho na posição exata da denúncia
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: reportLocation,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status + data de criação ──────────────────────────
                  Row(
                    children: [
                      _StatusChip(status: report.status),
                      const Spacer(),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Metadados da denúncia ────────────────────────────
                  _InfoRow(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.emergency,
                    label: 'Tipo',
                    value: report.fireLevel,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.cloud_outlined,
                    iconColor: Colors.grey,
                    label: 'Fumaça',
                    value: report.smokeLevel,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppColors.warning,
                    label: 'Risco',
                    // Fallback quando riskLevel não foi preenchido
                    value: report.riskLevel.isNotEmpty
                        ? report.riskLevel
                        : 'Não especificado',
                  ),
                  const SizedBox(height: 10),
                  // Coordenadas com 5 casas decimais (≈ 1 metro de precisão)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primary,
                    label: 'Coordenadas',
                    value:
                        '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                  ),
                  // Endereço legível (quando disponível via geocodificação reversa)
                  if (report.address != null && report.address!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      iconColor: AppColors.primary,
                      label: 'Endereço',
                      value: report.address!,
                    ),
                  ],
                  // Identificação anônima do denunciante
                  if (report.anonymous) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.person_off_outlined,
                      iconColor: AppColors.textLight,
                      label: 'Denunciante',
                      value: 'Anônimo',
                    ),
                  ],

                  // ── Descrição textual ────────────────────────────────
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Descrição',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    // Container com sombra para destacar o bloco de texto
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.shadow, blurRadius: 6)
                        ],
                      ),
                      child: Text(report.description,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textMedium)),
                    ),
                  ],

                  // ── Galeria de fotos ──────────────────────────────────
                  if (report.images.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Fotos (${report.images.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    // Lista horizontal rolável com thumbnails de 160×160px
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: report.images.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) => GestureDetector(
                          // Toque abre o _PhotoViewer na foto tocada
                          onTap: () => _openPhoto(context, report.images, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: report.images[i],
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              // Placeholder cinza com indicador enquanto carrega
                              placeholder: (_, __) => Container(
                                width: 160,
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              // Ícone de imagem quebrada em caso de erro
                              errorWidget: (_, __, ___) => Container(
                                width: 160,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Mensagem quando nenhuma foto foi anexada
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400, size: 18),
                        const SizedBox(width: 8),
                        const Text('Sem fotos anexadas.',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 13)),
                      ],
                    ),
                  ],

                  // ── Botões de status (somente para autoridade) ────────
                  // Ocultos quando readOnly == true (visualização do admin)
                  if (!readOnly) ...[
                    const SizedBox(height: 28),
                    const Text('Atualizar Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _StatusButtons(report: report),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navega para [_PhotoViewer] abrindo na foto de índice [initialIndex].
  void _openPhoto(
      BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PhotoViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }
}

// ── Botões de atualização de status ──────────────────────────────────────────

/// Conjunto de 3 botões para alterar o status de uma denúncia.
///
/// Exibido apenas quando [ReportDetailPage.readOnly] == false.
///
/// Botões disponíveis (Dart 3 Records):
///   • 'analisando' → 'Em Verificação' (roxo)
///   • 'atendida'   → 'Marcar Resolvida' (verde)
///   • 'rejeitada'  → 'Rejeitar' (vermelho)
///
/// O botão do status atual fica desabilitado (cinza) para evitar reenvio.
class _StatusButtons extends StatefulWidget {
  final ReportModel report;
  const _StatusButtons({required this.report});

  @override
  State<_StatusButtons> createState() => _StatusButtonsState();
}

class _StatusButtonsState extends State<_StatusButtons> {
  bool _loading = false;

  /// Campo de observações — preenchido opcionalmente antes de alterar o status.
  final _obsController = TextEditingController();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status atualizado! Usuário foi notificado.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    final buttons = [
      (AppConstants.statusAnalyzing, 'Em Verificação', Colors.purple,
          Icons.search_rounded),
      (AppConstants.statusAttended, 'Marcar Atendida', Colors.green,
          Icons.check_circle_rounded),
      (AppConstants.statusRejected, 'Rejeitar', Colors.red,
          Icons.cancel_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Observações (opcional) ─────────────────────────────────────
        const Text(
          'Observações (opcional):',
          style: TextStyle(fontSize: 13, color: AppColors.textMedium),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _obsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Registre o que foi feito, o que foi encontrado no local...',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),

        // ── Botões de status ───────────────────────────────────────────
        ...buttons.map((b) {
        final isCurrent = widget.report.status == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCurrent ? null : () => _setStatus(b.$1),
              icon: Icon(b.$4),
              label: Text(b.$2),
              style: ElevatedButton.styleFrom(
                // Cinza quando já é o status atual, cor do status caso contrário
                backgroundColor: isCurrent ? Colors.grey.shade200 : b.$3,
                foregroundColor:
                    isCurrent ? AppColors.textLight : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      }),
      ],    // fecha children do Column externo
    );
  }
}

// ── Linha de informação ───────────────────────────────────────────────────────

/// Linha de metadado com ícone colorido, label em negrito e valor.
///
/// Exemplo de uso: "🔥 Tipo: Urgente" ou "📍 Coordenadas: -8.12, -41.34"
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          // Label em negrito seguido de ":"
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          // Valor com quebra de linha automática
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium)),
          ),
        ],
      );
}

// ── Chip de status ────────────────────────────────────────────────────────────

/// Pill colorido exibindo o status atual da denúncia.
///
/// Usa Dart 3 switch expression para mapear chave → (cor, label).
/// Inclui ponto indicador de cor sólida à esquerda do texto.
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    // Mapeamento status → (cor, label legível)
    final (color, label) = switch (status) {
      AppConstants.statusPending   => (AppColors.statusPending,   'Pendente'),
      AppConstants.statusSent      => (AppColors.statusSent,      'Enviada'),
      AppConstants.statusAnalyzing => (AppColors.statusAnalyzing, 'Em Verificação'),
      AppConstants.statusAttended  => (AppColors.statusAttended,  'Atendida'),
      AppConstants.statusRejected  => (AppColors.textLight,       'Rejeitada'),
      _                            => (AppColors.textLight,        status), // fallback
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ponto indicador de cor sólida
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Visualizador de fotos fullscreen ──────────────────────────────────────────

/// Galeria fullscreen de fotos com fundo preto e navegação por swipe.
///
/// Funcionalidades:
///   • [PageView.builder] para deslizar entre fotos
///   • [InteractiveViewer] em cada foto para pinch-zoom na imagem
///   • [CachedNetworkImage] com placeholder e errorWidget
///   • Contador "X / N" no AppBar mostra posição atual
///   • Fundo e AppBar pretos para imersão
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewer({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;

  /// Índice da foto atualmente visível
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    // Inicializa o PageController na foto que o usuário tocou
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose(); // libera recursos do PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // Contador de posição: "1 / 3", "2 / 3", etc.
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        // Atualiza o contador quando o usuário muda de página
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          // Permite pinch-zoom em cada imagem individualmente
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain, // mantém proporção
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
