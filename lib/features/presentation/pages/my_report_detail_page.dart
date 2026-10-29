// ============================================================================
// my_report_detail_page.dart
// ----------------------------------------------------------------------------
// Tela de detalhes de uma denúncia do próprio usuário (cidadão).
//
// Esta tela é diferente de [ReportDetailPage] (que é exclusiva para
// autoridades e admins). Esta é a visão READ-ONLY do cidadão sobre sua
// própria denúncia, com foco em:
//   • Localização no mapa
//   • Status atual e sincronização
//   • Todos os dados preenchidos no formulário
//   • Fotos (locais no dispositivo OU URLs do Cloudinary)
//   • Resposta da autoridade (observações) quando houver
//
// Acesso:
//   • Tap em qualquer card de [MyReportsPage] navega para esta tela.
//   • Recebe o [ReportModel] completo por parâmetro.
//
// Imagens — comportamento por estado:
//   • Denúncia offline (synced=false): exibe fotos do dispositivo via File
//   • Denúncia sincronizada (synced=true): exibe URLs do Cloudinary via rede
//   • Transição: pode ter ambas (raro, apenas durante upload)
//
// Widgets internos:
//   • [_InfoRow]             — linha ícone + label + valor
//   • [_StatusBadge]         — pill colorido de status (igual ao MyReportsPage)
//   • [_SyncWarningCard]     — card laranja de aviso de pendência offline
//   • [_CitizenPhotoViewer]  — galeria fullscreen (PageView + InteractiveViewer)
//                              suporta File (local) e NetworkImage (remoto)
// ============================================================================

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../report/data/models/report_model.dart';
import '../../../services/api/api_service.dart';
import 'report_timeline_page.dart';

// ── Página principal ──────────────────────────────────────────────────────────

/// Tela de detalhes de uma denúncia do cidadão (somente leitura).
///
/// Exibe o mapa, todos os campos do formulário, fotos e a resposta da
/// autoridade. O cidadão não pode editar nem alterar o status.
class MyReportDetailPage extends StatefulWidget {
  /// Denúncia a ser exibida — passada pela [MyReportsPage].
  final ReportModel report;

  const MyReportDetailPage({super.key, required this.report});

  @override
  State<MyReportDetailPage> createState() => _MyReportDetailPageState();
}

class _MyReportDetailPageState extends State<MyReportDetailPage> {
  // Score buscado da API — null enquanto carrega ou se API indisponível
  late final Future<ScoreData?> _scoreFuture;

  @override
  void initState() {
    super.initState();
    _scoreFuture = ApiService.getScorePrioridade(widget.report.id);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final date = DateFormat('dd/MM/yyyy  HH:mm').format(report.createdAt);
    final location = LatLng(report.latitude, report.longitude);

    // ── Consolidação das imagens ──────────────────────────────────────────────
    // Imagens locais: paths de arquivo no dispositivo (presentes quando offline)
    // Imagens remotas: URLs do Cloudinary (presentes após sincronização)
    // Filtra localImages que o arquivo ainda existe no dispositivo (o SO pode ter
    // apagado arquivos temporários da câmera após reinicializações).
    final localImages = report.localImages
        .where((p) => File(p).existsSync())
        .toList();
    final remoteImages = report.images;
    final totalImages = localImages.length + remoteImages.length;
    final hasImages = totalImages > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minha Denúncia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded),
            tooltip: 'Ver histórico',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportTimelinePage(report: report),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mapa interativo ─────────────────────────────────────────────
            // Centrado nas coordenadas GPS capturadas no momento da denúncia.
            // Habilitado apenas pinch-zoom e drag (sem rotação).
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  // Tiles OpenStreetMap (sem API key necessária)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.voz_contra_o_fogo',
                  ),
                  // Marcador vermelho na posição exata da denúncia
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Conteúdo principal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Status + data de criação ────────────────────────────
                  Row(
                    children: [
                      _StatusBadge(status: report.status, synced: report.synced),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),

                  // ── Score de Prioridade (SemiáridoFogo API) ─────────────
                  // Só exibido quando o report foi enviado à API nesta sessão
                  FutureBuilder<ScoreData?>(
                    future: _scoreFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }
                      final score = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _ScoreCard(score: score),
                      );
                    },
                  ),

                  // ── Aviso de sincronização pendente ─────────────────────
                  // Exibido apenas quando a denúncia ainda não foi enviada
                  // ao servidor (salva localmente por falta de conexão)
                  if (!report.synced) ...[
                    const SizedBox(height: 14),
                    const _SyncWarningCard(),
                  ],

                  const SizedBox(height: 20),

                  // ── Informações da ocorrência ───────────────────────────
                  _InfoRow(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.emergency,
                    label: 'Nível do fogo',
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

                  // Endereço por extenso — preenchido via geocodificação reversa
                  if (report.address != null && report.address!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      iconColor: AppColors.primary,
                      label: 'Endereço',
                      value: report.address!,
                    ),
                  ],

                  // Badge de denúncia anônima
                  if (report.anonymous) ...[
                    const SizedBox(height: 10),
                    const _InfoRow(
                      icon: Icons.person_off_outlined,
                      iconColor: AppColors.textLight,
                      label: 'Enviada como',
                      value: 'Anônima',
                    ),
                  ],

                  // ── Descrição textual ───────────────────────────────────
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        report.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // ── Galeria de fotos ─────────────────────────────────────
                  // Exibe fotos locais (File) e remotas (URL) na mesma linha.
                  // Tap em qualquer foto abre o [_CitizenPhotoViewer] fullscreen.
                  const SizedBox(height: 24),
                  Text(
                    hasImages ? 'Fotos ($totalImages)' : 'Fotos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (hasImages) ...[
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: totalImages,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          // Índices 0..localImages.length-1 → arquivo local
                          // Índices localImages.length..total-1 → URL remota
                          final isLocal = i < localImages.length;

                          return GestureDetector(
                            onTap: () => _openPhoto(
                              context,
                              localImages,
                              remoteImages,
                              i,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: isLocal
                                  // Imagem do arquivo local no dispositivo
                                  ? Image.file(
                                      File(localImages[i]),
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _BrokenImage(),
                                    )
                                  // Imagem remota do Cloudinary com cache
                                  : CachedNetworkImage(
                                      imageUrl: remoteImages[
                                          i - localImages.length],
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const _LoadingImage(),
                                      errorWidget: (_, __, ___) =>
                                          _BrokenImage(),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Mensagem quando nenhuma foto foi anexada
                    Row(
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Nenhuma foto anexada.',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Resposta da autoridade ─────────────────────────────
                  // Exibido quando a autoridade preenche o campo 'observations'
                  // ao atualizar o status da denúncia no painel delas.
                  if (report.observations != null &&
                      report.observations!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.statusAnalyzing
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.comment_outlined,
                            color: AppColors.statusAnalyzing,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Resposta da Autoridade',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.statusAnalyzing
                              .withValues(alpha: 0.25),
                        ),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        report.observations!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // ── Rodapé: ID da denúncia ──────────────────────────────
                  // Exibe os primeiros 8 caracteres do UUID para o usuário
                  // referenciar em caso de necessidade de suporte.
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'ID: #${report.id.substring(0, report.id.length >= 8 ? 8 : report.id.length).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontFamily: 'monospace',
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhoto(
    BuildContext context,
    List<String> localPaths,
    List<String> remoteUrls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CitizenPhotoViewer(
          localPaths: localPaths,
          remoteUrls: remoteUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

/// Card de score de prioridade calculado pela SemiáridoFogo API.
///
/// Exibe o score 0–100, a barra de progresso colorida e a recomendação
/// gerada automaticamente pelos 5 fatores de ponderação da API.
class _ScoreCard extends StatelessWidget {
  final ScoreData score;
  const _ScoreCard({required this.score});

  Color get _scoreColor {
    if (score.score >= 75) return AppColors.emergency;
    if (score.score >= 50) return AppColors.warning;
    return AppColors.statusSent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: _scoreColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Score de Prioridade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${score.score.toStringAsFixed(0)}/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.recomendacao,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de metadado: ícone colorido + label cinza + valor em negrito.
///
/// Usado para exibir campos como "Nível do fogo: Médio", "Risco: Alto", etc.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone com fundo colorido translúcido
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (ex.: "Nível do fogo")
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              // Valor em negrito (ex.: "Médio")
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Badge colorido com ponto indicador e texto de status.
///
/// Casos especiais:
///   • synced=false → exibe "Pendente" em cinza (aguardando sincronização)
///   • Os demais status usam as cores definidas em [AppColors]
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool synced;

  const _StatusBadge({required this.status, required this.synced});

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status, synced);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo sólido indicador da cor do status
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.$1,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.$2,
            style: TextStyle(
              color: config.$1,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna (cor, label) com base no status e no estado de sincronização.
  /// Usa Record do Dart 3 (tupla de dois valores).
  (Color, String) _resolveConfig(String status, bool synced) {
    if (!synced) return (AppColors.textLight, 'Offline');
    switch (status) {
      case AppConstants.statusPending:
        return (AppColors.statusPending, 'Pendente');
      case AppConstants.statusSent:
        return (AppColors.statusSent, 'Enviada');
      case AppConstants.statusAnalyzing:
        return (AppColors.statusAnalyzing, 'Em análise');
      case AppConstants.statusAttended:
        return (AppColors.statusAttended, 'Atendida');
      default:
        return (AppColors.textLight, status);
    }
  }
}

/// Card laranja de aviso para denúncias não sincronizadas (offline).
///
/// Informa ao usuário que a denúncia está salva localmente e será
/// enviada automaticamente quando a internet retornar.
class _SyncWarningCard extends StatelessWidget {
  const _SyncWarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone de nuvem offline
          Icon(Icons.cloud_off, color: AppColors.warning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aguardando sincronização',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Esta denúncia está salva no dispositivo e será '
                  'enviada automaticamente quando a internet retornar.',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                    height: 1.4,
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

/// Placeholder de carregamento para imagens remotas (exibido enquanto baixa).
class _LoadingImage extends StatelessWidget {
  const _LoadingImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// Placeholder de erro para imagens que não puderam ser carregadas.
class _BrokenImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
    );
  }
}

// ── Visualizador de fotos fullscreen ──────────────────────────────────────────

/// Galeria de fotos em tela cheia com PageView e zoom por pinça.
///
/// Suporta dois tipos de imagem na mesma galeria:
///   • Fotos locais (File) — índices 0 a localPaths.length-1
///   • Fotos remotas (URL) — índices localPaths.length a total-1
///
/// Exibe contador "X / N" no canto superior direito e fundo preto.
/// O [InteractiveViewer] permite pinch-zoom individual por foto.
class _CitizenPhotoViewer extends StatefulWidget {
  final List<String> localPaths;   // paths de arquivo no dispositivo
  final List<String> remoteUrls;   // URLs do Cloudinary
  final int initialIndex;          // índice inicial do PageView

  const _CitizenPhotoViewer({
    required this.localPaths,
    required this.remoteUrls,
    required this.initialIndex,
  });

  @override
  State<_CitizenPhotoViewer> createState() => _CitizenPhotoViewerState();
}

class _CitizenPhotoViewerState extends State<_CitizenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.localPaths.length + widget.remoteUrls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        // Contador "foto atual / total"
        title: Text(
          '${_currentIndex + 1} / $total',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: total,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final isLocal = i < widget.localPaths.length;

          // InteractiveViewer permite zoom por pinça em cada foto individualmente
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: isLocal
                  // Foto local — lida diretamente do sistema de arquivos
                  ? Image.file(
                      File(widget.localPaths[i]),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    )
                  // Foto remota — baixada do Cloudinary com cache
                  : CachedNetworkImage(
                      imageUrl:
                          widget.remoteUrls[i - widget.localPaths.length],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
