// ============================================================================
// main.dart
// ----------------------------------------------------------------------------
// Ponto de entrada do aplicativo Voz Contra o Fogo.
//
// Responsabilidades desta camada:
//   1. Inicializar o Firebase (Auth, Firestore, Crashlytics)
//   2. Inicializar o Hive (armazenamento local offline-first)
//   3. Configurar o plugin de notificações locais (flutter_local_notifications)
//   4. Registrar o WorkManager para sincronização periódica em background
//   5. Configurar o Crashlytics para captura automática de erros fatais
//   6. Iniciar o app dentro de um ProviderScope (Riverpod)
//
// Ordem de inicialização (importantíssima):
//   WidgetsFlutterBinding → Firebase → Hive → Notificações → WorkManager → runApp
//
// Se Firebase ou Hive falharem, o app não deve iniciar (sem try/catch).
// Notificações e WorkManager são opcionais — falhas são silenciadas.
// ============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';
import 'firebase_options.dart';
import 'services/local/hive_service.dart';
import 'services/local/sync_service.dart';

// ── Plugin global de notificações locais ────────────────────────────────────
// Declarado como variável global para ser acessível no handler de background
// do FCM (firebaseMessagingBackgroundHandler em fcm_service.dart).
// O handler top-level não tem acesso ao BuildContext nem ao estado do widget,
// por isso precisa de uma instância global disponível em todo o processo.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ── Dispatcher do WorkManager ────────────────────────────────────────────────
// Função top-level exigida pelo WorkManager — não pode ser método de classe.
// O WorkManager executa esta função em um processo isolado (background isolate),
// chamando-a a cada 15 minutos quando há conexão de internet.
//
// @pragma('vm:entry-point') garante que a função não seja removida pelo
// tree-shaking da compilação AOT em release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Só executa se for a tarefa de sincronização registrada
    if (task == AppConstants.syncTaskName) {
      // O background isolate do WorkManager não compartilha estado com o
      // isolate principal — Firebase E Hive precisam ser reinicializados aqui.
      //
      // Firebase.apps.isEmpty: evita erro "app already exists" caso o isolate
      // seja reaproveitado em execuções consecutivas.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Hive também precisa ser reaberto no processo de background
      await HiveService.init();

      // Processa a fila de denúncias pendentes
      await SyncService.syncPendingReports();
    }
    return true; // indica que a tarefa foi concluída com sucesso
  });
}

// ── Função principal ─────────────────────────────────────────────────────────
void main() async {
  // Garante que os bindings do Flutter estejam prontos antes de qualquer
  // chamada a plugins (obrigatório antes de Firebase.initializeApp).
  WidgetsFlutterBinding.ensureInitialized();

  // ── Locale de datas (intl) — obrigatório para DateFormat funcionar ───────
  await initializeDateFormatting('pt_BR');

  // ── Firebase — obrigatório ───────────────────────────────────────────────
  // DefaultFirebaseOptions é gerado pelo FlutterFire CLI e lê as credenciais
  // do google-services.json (Android) ou GoogleService-Info.plist (iOS).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive — obrigatório ───────────────────────────────────────────────────
  // Abre os boxes necessários (reports, user, settings, pendingSync).
  // Deve ser inicializado antes do runApp pois providers Riverpod
  // acessam o Hive durante a construção inicial da árvore de widgets.
  await HiveService.init();

  // ── Notificações locais — opcional ──────────────────────────────────────
  // Falha silenciosa: o app funciona sem notificações locais.
  // Necessário para exibir alertas de push quando o app está em foreground.
  try {
    await _initNotifications();
  } catch (_) {}

  // ── WorkManager — opcional ───────────────────────────────────────────────
  // Registra tarefa periódica de sincronização (a cada 15 minutos).
  // Constraints: só executa com rede disponível (networkType: connected).
  // isInDebugMode: true em debug → logs detalhados no Logcat.
  // Falha silenciosa: o app funciona sem sincronização em background;
  // o usuário pode sincronizar manualmente via ReportController.syncPending().
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    await Workmanager().registerPeriodicTask(
      AppConstants.syncTaskName, // ID único da tarefa
      AppConstants.syncTaskName, // nome descritivo (igual ao ID por convenção)
      frequency: const Duration(minutes: 15), // frequência mínima no Android
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (_) {}

  // ── Inicia o app ─────────────────────────────────────────────────────────
  // ProviderScope é o widget raiz do Riverpod — obrigatório para que todos
  // os providers funcionem. Deve envolver o MaterialApp.
  runApp(const ProviderScope(child: VozContraOFogoApp()));
}

// ── Inicialização das notificações locais ────────────────────────────────────
/// Configura o plugin de notificações locais para Android.
///
/// AndroidInitializationSettings: usa o ícone do app como ícone da notificação.
/// O canal de notificação 'voz_contra_fogo_channel' é criado automaticamente
/// pelo Android 8+ ao receber a primeira notificação com esse ID.
Future<void> _initNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

// ── Widget raiz do aplicativo ────────────────────────────────────────────────

/// Widget raiz sem estado — apenas configura o MaterialApp.
///
/// Não usa Consumer/ConsumerWidget pois não precisa ler providers.
/// O tema, título e rota inicial são definidos aqui.
class VozContraOFogoApp extends StatelessWidget {
  const VozContraOFogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // remove o banner vermelho de debug
      title: 'Voz Contra o Fogo',
      theme: AppTheme.lightTheme,        // tema centralizado em app_theme.dart
      home: const SplashPage(),          // tela inicial com animação e roteamento
    );
  }
}
