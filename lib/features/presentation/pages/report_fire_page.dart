// ============================================================================
// report_fire_page.dart
// ----------------------------------------------------------------------------
// Tela de envio de nova denúncia de incêndio — formulário em 4 etapas.
//
// Estrutura do formulário:
//   Etapa 1 — Localização:  [_LocationCard] com GPS automático + mini mapa
//                            + botão "Marcar no Mapa Manualmente" (_MapPickerSheet)
//   Etapa 2 — Imagem:       [_ImageSection] câmera / galeria + preview horizontal
//   Etapa 3 — Descrição:    TextField livre com hint contextual
//   Etapa 4 — Classificação: seleção de tipo de ocorrência + fumaça + modo anônimo
//
// Fluxo de submissão (gerenciado pelo ReportController):
//   1. Valida descrição e GPS obrigatórios
//   2. Chama reportControllerProvider.notifier.submitReport(...)
//   3. Escuta [ReportState] via ref.listen:
//      • success=true, savedOffline=false → SnackBar verde + pop
//      • success=true, savedOffline=true  → SnackBar com ícone de nuvem + pop
//      • error != null                    → SnackBar de erro
//
// Localização GPS:
//   • _getLocation() solicita permissão via permission_handler
//   • Usa geolocator com LocationAccuracy.high
//   • Mini mapa interativo (read-only) exibe o pino na posição capturada
//   • [_MapPickerSheet] permite ajuste manual via toque no mapa
//
// Imagens:
//   • Limite de 5 fotos da galeria (pickMultiImage com limit: 5)
//   • Câmera também disponível (1 foto por vez)
//   • Compressão pré-seleção: imageQuality = AppConstants.imageQuality (70)
//   • Preview horizontal removível com botão X
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../report/presentation/controllers/report_controller.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../services/api/django_report_service.dart';

/// Tela de formulário para envio de uma nova denúncia de incêndio.
///
/// Usa [ConsumerStatefulWidget] para gerenciar estado local do formulário
/// (campos, imagens, coordenadas) e acessar o ReportController via Riverpod.
class ReportFirePage extends ConsumerStatefulWidget {
  const ReportFirePage({super.key});

  @override
  ConsumerState<ReportFirePage> createState() => _ReportFirePageState();
}

class _ReportFirePageState extends ConsumerState<ReportFirePage> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  // ── Estado do formulário ─────────────────────────────────────────────────
  bool _isAnonymous = false;                                     // toggle anônimo
  String _selectedFireLevel = AppConstants.fireLevelMedium;     // nível do fogo
  String _selectedSmokeLevel = AppConstants.smokeLevelMedium;   // intensidade da fumaça
  String _selectedRiskLevel = '';                                // risco (inicializado no initState)

  /// Opções de risco/tipo de ocorrência exibidas como chips selecionáveis.
  final _riskOptions = [
    AppConstants.fireLevelSmall,
    AppConstants.fireLevelMedium,
    AppConstants.fireLevelNearHome,
    AppConstants.fireLevelUrgent,
  ];

  final List<File> _selectedImages = []; // lista de imagens selecionadas

  /// Limite máximo de fotos por denúncia.
  static const int _maxImages = 5;

  /// Guard contra chamadas concorrentes ao image picker.
  /// Evita crash quando o usuário toca rápido em câmera/galeria
  /// enquanto o picker ainda está abrindo.
  bool _isPicking = false;

  // ── Estado de localização GPS ────────────────────────────────────────────
  double? _latitude;
  double? _longitude;
  String? _address;          // endereço geocodificado (não implementado, reservado)
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedRiskLevel = _riskOptions[1]; // default: "Médio"
    _getLocation();                        // inicia busca do GPS imediatamente
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Localização GPS ───────────────────────────────────────────────────────

  /// Solicita permissão de localização e obtém as coordenadas GPS atuais.
  ///
  /// Se a permissão for negada, encerra sem coordenadas (usuário poderá
  /// ajustar manualmente via _MapPickerSheet).
  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _loadingLocation = false;
      });
    } catch (e) {
      // GPS indisponível ou erro → usuário pode marcar manualmente
      setState(() => _loadingLocation = false);
    }
  }

  /// Abre o [_MapPickerSheet] como bottom sheet para seleção manual de coordenadas.
  ///
  /// O centro inicial do mapa é a posição GPS atual (ou o ponto padrão
  /// de Paulistana/PI se o GPS não estiver disponível).
  /// O resultado é um [LatLng] com as coordenadas selecionadas pelo toque no mapa.
  Future<void> _pickFromMap() async {
    final initial = LatLng(
      _latitude ?? AppConstants.defaultLat,
      _longitude ?? AppConstants.defaultLng,
    );
    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapPickerSheet(initial: initial),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  // ── Imagens ──────────────────────────────────────────────────────────────

  /// Captura uma foto pela câmera do dispositivo.
  ///
  /// Correções aplicadas:
  ///   • Guard [_isPicking] evita chamadas concorrentes (crash ao tirar 2ª foto)
  ///   • Verifica [Permission.camera.status] ANTES de chamar .request()
  ///     — chamar .request() em permissão já concedida causa crash em alguns
  ///     Android (activity restart inesperado durante fechamento da câmera)
  ///   • [mounted] verificado após cada await para evitar setState em widget desmontado
  ///   • try/catch garante que qualquer exceção do picker seja tratada
  Future<void> _pickFromCamera() async {
    // Evita abrir dois pickers ao mesmo tempo
    if (_isPicking) return;
    _isPicking = true;

    try {
      // Verifica status atual sem disparar dialog desnecessário
      var status = await Permission.camera.status;
      if (status.isDenied || status.isRestricted) {
        status = await Permission.camera.request();
      }

      if (!mounted) return;

      if (!status.isGranted) {
        _showSnack('Permissão de câmera necessária para tirar fotos.');
        return;
      }

      // Verifica limite antes de abrir a câmera
      if (_selectedImages.length >= _maxImages) {
        _showSnack('Limite de $_maxImages fotos atingido.');
        return;
      }

      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConstants.imageQuality,
      );

      // mounted: garante que o widget ainda está na árvore após o await
      if (photo != null && mounted) {
        setState(() => _selectedImages.add(File(photo.path)));
      }
    } catch (e) {
      // Qualquer exceção do picker (ex.: câmera indisponível, Activity destruída)
      if (mounted) _showSnack('Não foi possível capturar a foto. Tente novamente.');
    } finally {
      // Libera o guard sempre, mesmo em caso de erro
      _isPicking = false;
    }
  }

  /// Seleciona múltiplas fotos da galeria (até [_maxImages] no total).
  ///
  /// Correções aplicadas:
  ///   • Guard [_isPicking] evita chamadas concorrentes
  ///   • Removido parâmetro `limit:` do pickMultiImage — não é suportado
  ///     em todas as versões do image_picker e causa crash silencioso
  ///   • Limite aplicado manualmente após a seleção
  ///   • try/catch para qualquer falha do picker
  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      // Calcula quantas fotos ainda podem ser adicionadas
      final remaining = _maxImages - _selectedImages.length;
      if (remaining <= 0) {
        _showSnack('Limite de $_maxImages fotos atingido.');
        return;
      }

      // Nota: sem parâmetro `limit:` para compatibilidade máxima de versões
      final photos = await _picker.pickMultiImage(
        imageQuality: AppConstants.imageQuality,
      );

      if (!mounted) return;

      if (photos.isEmpty) return;

      // Respeita o limite máximo: pega apenas as primeiras [remaining] fotos
      final toAdd = photos.take(remaining).map((p) => File(p.path)).toList();
      setState(() => _selectedImages.addAll(toAdd));

      // Informa se a seleção foi truncada
      if (photos.length > remaining) {
        _showSnack(
          'Apenas $remaining foto(s) adicionada(s). '
          'Limite de $_maxImages fotos por denúncia.',
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Não foi possível selecionar as fotos. Tente novamente.');
    } finally {
      _isPicking = false;
    }
  }

  /// Remove uma imagem da lista pelo índice.
  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ── Submissão ─────────────────────────────────────────────────────────────

  /// Valida o formulário e envia a denúncia via ReportController.
  ///
  /// Validações:
  ///   1. Descrição não pode ser vazia
  ///   2. Coordenadas GPS devem estar disponíveis
  ///   3. Verificação de duplicata via API (aviso, não bloqueio)
  /// Se válido, chama submitReport e aguarda o estado via ref.listen (no build).
  Future<void> _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Descreva o que está acontecendo.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showSnack('Aguarde a detecção do GPS ou ative sua localização.');
      return;
    }

    // Verificação de duplicata via Django API
    final descLen = _descriptionController.text.trim().length.clamp(0, 50);
    final titulo =
        '$_selectedFireLevel — ${_descriptionController.text.trim().substring(0, descLen)}';
    final duplicata = await DjangoReportService.detectDuplicate(
      lat: _latitude!,
      lng: _longitude!,
      titulo: titulo,
    );

    // is_duplicate: true e confiança ≥ 0.7 → aviso, não bloqueio
    final isDup = duplicata?['is_duplicate'] as bool? ?? false;
    final confianca = (duplicata?['confianca'] as num?)?.toDouble() ?? 0.0;
    if (isDup && confianca >= 0.7) {
      if (!mounted) return;
      final pct = (confianca * 100).toStringAsFixed(0);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Possível Duplicata'),
            ],
          ),
          content: Text(
            'Encontramos uma denúncia semelhante nas últimas 24 horas a menos '
            'de 500 metros daqui ($pct% de similaridade).\n\n'
            'Deseja enviar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar assim mesmo'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;

    await ref.read(reportControllerProvider.notifier).submitReport(
          latitude: _latitude!,
          longitude: _longitude!,
          address: _address,
          description: _descriptionController.text.trim(),
          fireLevel: _selectedFireLevel,
          smokeLevel: _selectedSmokeLevel,
          riskLevel: _selectedRiskLevel,
          // Se o usuário Firebase for anônimo OU tiver ativado o toggle manualmente
          anonymous: _isAnonymous || (ref.read(authStateProvider)?.isAnonymous ?? false),
          images: _selectedImages,
        );
  }

  /// Exibe um SnackBar flutuante com a mensagem informada.
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportControllerProvider);

    // ── Listener de estado do envio ──────────────────────────────────────
    // Reagir a mudanças no ReportState: sucesso (online/offline) ou erro
    ref.listen<ReportState>(reportControllerProvider, (_, next) {
      if (next.success) {
        final msg = next.savedOffline
            ? 'Denúncia salva! Será enviada quando houver conexão.'
            : 'Denúncia enviada com sucesso!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(
                next.savedOffline ? Icons.cloud_off : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ]),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        // Reseta o estado e fecha a tela após feedback
        ref.read(reportControllerProvider.notifier).reset();
        Navigator.pop(context);
      }
      if (next.error != null) {
        _showSnack(next.error!);
        ref.read(reportControllerProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reportar Incêndio'),
      ),
      // Barra de envio fixa na parte inferior (fora do scroll)
      bottomNavigationBar: _SubmitBar(
        isLoading: reportState.isLoading,
        onTap: _submit,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Etapa 1 — Localização ────────────────────────────────
            _stepTitle('1', 'Localização'),
            const SizedBox(height: 12),
            _LocationCard(
              latitude: _latitude,
              longitude: _longitude,
              isLoading: _loadingLocation,
              onRefresh: _getLocation,
              onPickMap: _pickFromMap,
            ),
            const SizedBox(height: 28),

            // ── Etapa 2 — Imagem ─────────────────────────────────────
            _stepTitle('2', 'Anexar Imagem'),
            const SizedBox(height: 12),
            _ImageSection(
              images: _selectedImages,
              maxImages: _maxImages,
              onCamera: _pickFromCamera,
              onGallery: _pickFromGallery,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 28),

            // ── Etapa 3 — Descrição ──────────────────────────────────
            _stepTitle('3', 'Descrição'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText:
                      'Descreva a situação (ex: tamanho das chamas, proximidade de árvores, se há pessoas em perigo)...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Etapa 4 — Classificação ──────────────────────────────
            _stepTitle('4', 'Classificação'),
            const SizedBox(height: 14),

            // Chips de tipo de ocorrência
            const Text(
              'Tipo de ocorrência:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _riskOptions.map((opt) {
                final selected = _selectedRiskLevel == opt;
                final isUrgent = opt == AppConstants.fireLevelUrgent;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedRiskLevel = opt;
                    _selectedFireLevel = opt; // sincroniza fireLevel com a seleção
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      // Chip selecionado: preenchido; não selecionado: borda
                      color: selected
                          ? (isUrgent ? AppColors.emergency : AppColors.primary)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isUrgent
                            ? AppColors.emergency
                            : AppColors.primary,
                        width: selected ? 0 : 1.5,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isUrgent ? AppColors.emergency : AppColors.primary),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Chips de intensidade de fumaça
            const Text(
              'Intensidade da fumaça:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AppConstants.smokeLevelLight,
                AppConstants.smokeLevelMedium,
                AppConstants.smokeLevelHeavy,
              ].map((level) {
                final selected = _selectedSmokeLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSmokeLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Toggle de denúncia anônima
            // Se o usuário Firebase já é anônimo, o toggle fica travado em "ligado"
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Denúncia Anônima',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Suas informações não serão compartilhadas',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous || (ref.watch(authStateProvider)?.isAnonymous ?? false),
                    activeColor: AppColors.primary,
                    onChanged: (ref.watch(authStateProvider)?.isAnonymous ?? false)
                        ? null
                        : (v) => setState(() => _isAnonymous = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Center(
              child: Text(
                'VOZ CONTRA O FOGO • PROTEGENDO O MEIO AMBIENTE',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 100), // espaço para o _SubmitBar
          ],
        ),
      ),
    );
  }

  /// Constrói um título de etapa numerada (número em círculo + texto).
  Widget _stepTitle(String number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Card da etapa de Localização com GPS, mini mapa e botão de seleção manual.
///
/// • Exibe "Detectando coordenadas GPS..." durante o loading
/// • Exibe as coordenadas e um mini mapa estático ao obter o GPS
/// • "GPS não disponível" se a permissão for negada
/// • Botão "Marcar no Mapa Manualmente" → [_MapPickerSheet]
class _LocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onPickMap;

  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.isLoading,
    required this.onRefresh,
    required this.onPickMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── Status do GPS ─────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localização Atual',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isLoading
                          ? 'Detectando coordenadas GPS...'
                          : latitude != null
                              ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                              : 'GPS não disponível',
                      style: TextStyle(
                        fontSize: 12,
                        color: latitude != null
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão para reatualizar o GPS
              TextButton(
                onPressed: isLoading ? null : onRefresh,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Atualizar'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Mini mapa (ou placeholder) ────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: latitude != null
                  // Mini mapa estático (interação desabilitada)
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude!, longitude!),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none, // somente leitura
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.voz_contra_o_fogo',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(latitude!, longitude!),
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 36),
                          ),
                        ]),
                      ],
                    )
                  // Placeholder enquanto GPS não está disponível
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                color: AppColors.textLight, size: 48),
                            const SizedBox(height: 8),
                            const Text('Aguardando GPS...',
                                style:
                                    TextStyle(color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Botão seleção manual no mapa ──────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPickMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Marcar no Mapa Manualmente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção de seleção de imagens com botões câmera/galeria e preview removível.
///
/// Preview horizontal com scroll permite ver todas as fotos selecionadas.
/// Cada foto tem um botão X (preto semitransparente) para remoção individual.
/// Contador "X / 5" informa quantas fotos foram adicionadas.
class _ImageSection extends StatelessWidget {
  final List<File> images;

  /// Limite máximo de fotos — sincronizado com _ReportFirePageState._maxImages
  final int maxImages;

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final void Function(int) onRemove;

  const _ImageSection({
    required this.images,
    required this.maxImages,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final atLimit = images.length >= maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Botões câmera e galeria ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _imageButton(
                Icons.photo_camera,
                'Tirar Foto',
                // Desabilita visualmente quando atingiu o limite
                atLimit ? null : onCamera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _imageButton(
                Icons.photo_library,
                'Galeria',
                atLimit ? null : onGallery,
              ),
            ),
          ],
        ),

        // ── Contador e preview das fotos selecionadas ──────────────────
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Contador "X de 5 fotos"
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 14,
                color: atLimit ? AppColors.emergency : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${images.length} de $maxImages foto(s) • Toque no ✕ para remover',
                style: TextStyle(
                  fontSize: 12,
                  color: atLimit ? AppColors.emergency : AppColors.textLight,
                  fontWeight: atLimit ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Preview horizontal com scroll
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Stack(
                children: [
                  // Thumbnail da imagem (com tratamento de erro de leitura)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      images[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      // Fallback se o arquivo não puder ser lido
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Botão X para remover a foto individualmente
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Mensagem de limite atingido
        if (atLimit) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Limite de $maxImages fotos atingido. Remova uma para adicionar outra.',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Botão de ação (câmera ou galeria) com ícone centralizado.
  ///
  /// [onTap] == null → botão desabilitado (atLimit) com opacidade reduzida.
  Widget _imageButton(IconData icon, String text, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de envio fixa na parte inferior da tela.
///
/// Exibe botão "Enviar Denúncia" (verde) ou spinner de loading.
/// Desabilitado durante o envio para evitar double-submit.
class _SubmitBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitBar({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20)],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
        ),
        onPressed: isLoading ? null : onTap, // desabilitado durante loading
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          isLoading ? 'Enviando...' : 'Enviar Denúncia',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Seletor de localização no mapa ────────────────────────────────────────────

/// Bottom sheet com mapa interativo para seleção manual de coordenadas.
///
/// O usuário toca no mapa para mover o marcador vermelho.
/// "Confirmar Localização" retorna o [LatLng] selecionado para o formulário.
/// Cancelar (fechar sheet) não retorna nada (null).
class _MapPickerSheet extends StatefulWidget {
  final LatLng initial; // ponto inicial do marcador (posição GPS atual)
  const _MapPickerSheet({required this.initial});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late LatLng _tapped; // posição atual do marcador no mapa

  @override
  void initState() {
    super.initState();
    _tapped = widget.initial; // inicia no GPS atual
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle visual do bottom sheet
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Toque no mapa para marcar o local',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Arraste ou dê zoom para ajustar',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),

          // ── Mapa interativo ────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _tapped,
                  initialZoom: 14,
                  // Toque no mapa → move o marcador para a posição tocada
                  onTap: (_, point) => setState(() => _tapped = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.voz_contra_o_fogo',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _tapped,
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
          ),

          // ── Rodapé: coordenadas + botão confirmar ──────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Exibe as coordenadas selecionadas em tempo real
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${_tapped.latitude.toStringAsFixed(5)}, ${_tapped.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Botão confirmar → retorna o LatLng selecionado
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, _tapped),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Confirmar Localização',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
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
