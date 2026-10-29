// ============================================================================
// storage_service.dart
// ----------------------------------------------------------------------------
// Serviço de upload de imagens para o Cloudinary (CDN gratuito).
//
// Antes de enviar, as imagens são comprimidas pelo flutter_image_compress
// para reduzir o tamanho do upload (qualidade 70%, máx 1080px).
//
// Estrutura de pastas no Cloudinary:
//   report_images/{reportId}/{uuid}.jpg
//
// Configuração necessária:
//   • cloudinaryCloudName: nome da conta Cloudinary (ver AppConstants)
//   • cloudinaryUploadPreset: preset do tipo "Unsigned" criado no painel
//     Cloudinary em Settings → Upload → Upload Presets
//
// Plano gratuito: 25GB de armazenamento + 25GB de banda por mês.
// Para o volume acadêmico atual, é suficiente sem custo.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

class StorageService {
  static const Uuid _uuid = Uuid();

  // ── Upload de uma única imagem ──────────────────────────────────────────────

  /// Comprime e envia uma imagem ao Cloudinary.
  ///
  /// [imageFile] — arquivo local selecionado pelo usuário via image_picker.
  /// [reportId] — ID da denúncia, usado como subpasta no Cloudinary.
  ///
  /// Retorna a URL segura (https) da imagem hospedada.
  /// Lança [UploadFailure] em caso de erro de rede ou resposta inválida.
  static Future<String> uploadReportImage(
    File imageFile,
    String reportId,
  ) async {
    try {
      // 1. Comprime a imagem antes de enviar (reduz banda e tempo de upload)
      final compressed = await _compressImage(imageFile);

      // 2. Monta a requisição multipart para a API do Cloudinary
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
        ..fields['folder'] = 'report_images/$reportId'
        ..files.add(await http.MultipartFile.fromPath('file', compressed.path));

      // 3. Envia e aguarda a resposta
      final streamed = await request.send();
      final body = jsonDecode(await streamed.stream.bytesToString());

      if (streamed.statusCode != 200) {
        throw UploadFailure(
          'Cloudinary erro ${streamed.statusCode}: ${body['error']?['message']}',
        );
      }

      // 4. Retorna a URL segura (https) da imagem no CDN
      return body['secure_url'] as String;
    } catch (e) {
      if (e is UploadFailure) rethrow; // re-lança sem envolver novamente
      throw UploadFailure('Erro ao enviar imagem: $e');
    }
  }

  // ── Upload de múltiplas imagens ─────────────────────────────────────────────

  /// Envia múltiplas imagens em paralelo usando Future.wait.
  /// Retorna a lista de URLs na mesma ordem das imagens recebidas.
  static Future<List<String>> uploadMultipleImages(
    List<File> images,
    String reportId,
  ) async {
    final futures = images.map((img) => uploadReportImage(img, reportId));
    return Future.wait(futures);
  }

  // ── Compressão local ────────────────────────────────────────────────────────

  /// Comprime uma imagem para o tamanho e qualidade configurados em [AppConstants].
  ///
  /// Salva o resultado como JPEG em um arquivo temporário com UUID único.
  /// Se a compressão falhar por qualquer motivo, retorna o arquivo original.
  static Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: AppConstants.imageQuality,       // 70%
      minWidth: AppConstants.imageMaxWidth,      // 1080px
      minHeight: AppConstants.imageMaxHeight,    // 1080px
    );

    // Fallback: retorna original se compressão falhou
    return result != null ? File(result.path) : file;
  }
}
