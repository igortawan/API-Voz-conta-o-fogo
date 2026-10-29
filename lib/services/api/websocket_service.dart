import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/report/data/models/report_model.dart';
import 'auth_api_service.dart';
import '../../core/constants/app_constants.dart';

/// Serviço WebSocket — substitui os listeners em tempo real do Firestore.
///
/// O Django Channels mantém a conexão aberta e envia eventos:
///   • nova_ocorrencia       → nova denúncia (para autoridades)
///   • ocorrencia_atualizada → status mudou (para o cidadão dono)
///   • novo_alerta           → alerta de risco (para todos)
class WebSocketService {
  static WebSocketChannel? _channel;
  static final _reportController = StreamController<ReportModel>.broadcast();
  static final _updateController = StreamController<ReportModel>.broadcast();
  static final _alertController = StreamController<Map<String, dynamic>>.broadcast();

  static Stream<ReportModel> get onNewReport => _reportController.stream;
  static Stream<ReportModel> get onReportUpdated => _updateController.stream;
  static Stream<Map<String, dynamic>> get onNewAlert => _alertController.stream;

  static Future<void> connect() async {
    final token = await AuthApiService.accessToken;
    if (token == null) return;

    final wsUrl = AppConstants.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/reports/?token=$token'),
    );

    _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnect,
      onError: (_) => _scheduleReconnect(),
    );
  }

  static void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (msg['type']) {
        case 'nova_ocorrencia':
          final r = ReportModel.fromDjangoMap(msg['ocorrencia'] as Map<String, dynamic>);
          _reportController.add(r);
        case 'ocorrencia_atualizada':
          final r = ReportModel.fromDjangoMap(msg['ocorrencia'] as Map<String, dynamic>);
          _updateController.add(r);
        case 'novo_alerta':
          _alertController.add(msg['alerta'] as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  static void _onDisconnect() => _scheduleReconnect();

  static void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), connect);
  }

  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
