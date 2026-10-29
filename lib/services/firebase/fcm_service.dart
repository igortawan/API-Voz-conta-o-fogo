// ============================================================================
// fcm_service.dart
// ----------------------------------------------------------------------------
// Serviço de notificações push via Firebase Cloud Messaging (FCM).
//
// !! IMPORTANTE — FCM HTTP v1 API !!
// A Legacy API (/fcm/send com Server Key) foi encerrada em junho/2024.
// Esta implementação usa a FCM HTTP v1 API com autenticação OAuth2
// via Conta de Serviço (Service Account). As credenciais estão em
// firebase_service_account.dart — NÃO commite esse arquivo no Git.
//
// Fluxo de envio de push (quando uma denúncia é criada):
//   1. ReportController chama FcmService.sendTopicNotification(...)
//   2. FcmService obtém token OAuth2 temporário via googleapis_auth
//   3. Faz POST para https://fcm.googleapis.com/v1/projects/{id}/messages:send
//   4. FCM entrega a notificação a todos os dispositivos inscritos no tópico
//
// Tópicos utilizados:
//   • AppConstants.fcmAuthorityTopic ('authority_alerts') — todas as autoridades
//     se inscrevem via subscribeToTopic() no login.
// ============================================================================

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../../core/constants/firebase_service_account.dart';
import '../../main.dart';

// ── Handler de mensagens em background ────────────────────────────────────────
// Deve ser uma função top-level (não pode ser método de classe) por exigência
// do plugin firebase_messaging quando o app está em background/terminado.

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Exibe notificação local mesmo com o app fechado
  _showLocalNotification(message);
}

class FcmService {
  static final _fcm = FirebaseMessaging.instance;

  /// Escopo OAuth2 necessário para enviar mensagens pela FCM HTTP v1 API.
  static const _fcmScope =
      'https://www.googleapis.com/auth/firebase.messaging';

  // ── Inicialização ───────────────────────────────────────────────────────────

  /// Inicializa o FCM: solicita permissão, registra handlers de mensagem.
  /// Chamado na SplashPage após a autenticação do usuário.
  static Future<void> init() async {
    // Solicita permissão para notificações (iOS obrigatório, Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler para mensagens recebidas enquanto o app está em background/fechado
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handler para mensagens recebidas enquanto o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message); // exibe notificação local
    });

    // Garante que as notificações apareçam mesmo em foreground (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Token e Tópicos ─────────────────────────────────────────────────────────

  /// Obtém o token FCM único do dispositivo.
  /// Salvo no Firestore para envios diretos (device-to-device) futuramente.
  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null; // Falha silenciosa — não interrompe o login
    }
  }

  /// Inscreve o dispositivo em um tópico FCM.
  /// Autoridades recebem notificações ao serem inscritas em 'authority_alerts'.
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (_) {}
  }

  /// Remove a inscrição do dispositivo em um tópico FCM.
  /// Chamado quando a autoridade faz logout.
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  // ── Envio de Push (FCM HTTP v1 API) ────────────────────────────────────────

  /// Envia uma notificação push para todos os dispositivos inscritos em [topic].
  ///
  /// [topic] — tópico FCM (ex.: 'authority_alerts')
  /// [title] — título da notificação
  /// [body] — corpo da notificação
  /// [data] — mapa de dados extras (ex.: {'reportId': '...', 'type': '...'})
  ///
  /// Falhas de rede são logadas no console mas não propagadas — o fluxo
  /// principal (salvar a denúncia) não é interrompido por falha de push.
  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Verifica se as credenciais reais foram configuradas
    if (FirebaseServiceAccount.isPlaceholder) {
      // ignore: avoid_print
      print('[FCM] Credenciais não configuradas — configure firebase_service_account.dart');
      return;
    }

    try {
      // 1. Obtém token OAuth2 temporário via Service Account
      final accountCredentials = ServiceAccountCredentials.fromJson(
        FirebaseServiceAccount.credentials,
      );
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        [_fcmScope],
      );

      // 2. Monta e envia a requisição para a FCM v1 API
      const projectId = FirebaseServiceAccount.projectId;
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final response = await authClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            // Configurações Android: alta prioridade + canal de notificação
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'voz_contra_fogo_channel',
                'sound': 'default',
                'default_sound': true,
              },
            },
            // Configurações iOS: som padrão
            'apns': {
              'payload': {
                'aps': {'sound': 'default'},
              },
            },
          },
        }),
      );

      // 3. Fecha o cliente HTTP OAuth2 para liberar recursos
      authClient.close();

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('[FCM] Erro ao enviar push: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FCM] Exceção ao enviar push: $e');
    }
  }
}

// ── Notificação local (foreground + background) ────────────────────────────────

/// Exibe uma notificação local no dispositivo.
/// Chamado tanto em foreground (app aberto) quanto em background (handler top-level).
///
/// Usa o canal 'voz_contra_fogo_channel' configurado com prioridade máxima.
void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return; // Mensagem de dados sem payload de notificação

  const androidDetails = AndroidNotificationDetails(
    'voz_contra_fogo_channel',       // ID do canal (deve coincidir com o Android manifest)
    'Voz Contra o Fogo',             // Nome visível ao usuário nas configurações do app
    channelDescription: 'Notificações de denúncias e alertas de incêndio',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',     // Ícone do app na notificação
  );

  flutterLocalNotificationsPlugin.show(
    notification.hashCode, // ID único da notificação (evita duplicatas)
    notification.title,
    notification.body,
    const NotificationDetails(android: androidDetails),
  );
}
