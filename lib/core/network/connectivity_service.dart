// ============================================================================
// connectivity_service.dart
// ----------------------------------------------------------------------------
// Serviço de monitoramento de conectividade de rede.
//
// Expõe dois providers Riverpod:
//   • [connectivityProvider] — Stream<bool> que emite true/false a cada
//     mudança de conexão. Use em widgets para reagir em tempo real.
//   • [isOnlineProvider] — Future<bool> que verifica o estado atual UMA vez.
//     Use em controllers antes de tentar uma operação de rede.
//
// Internamente usa o pacote connectivity_plus que suporta Wi-Fi, dados
// móveis, ethernet e VPN no Android e iOS.
// ============================================================================

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider de Stream que emite `true` quando há conexão de rede ativa.
/// Emite `false` ao perder a conexão. Ideal para monitoramento contínuo.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.onConnectivityChanged;
});

/// Provider de Future que verifica UMA vez se há conexão disponível.
/// Use antes de operações de rede no controller: `await ref.read(isOnlineProvider.future)`.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  return ConnectivityService.isOnline();
});

/// Classe de baixo nível que encapsula o connectivity_plus.
class ConnectivityService {
  static final _connectivity = Connectivity();

  /// Stream contínua de status de rede.
  /// Emite `true` se qualquer interface de rede está ativa (Wi-Fi, móvel, ethernet).
  /// Emite `false` se todos os resultados são [ConnectivityResult.none].
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
  }

  /// Verificação pontual do estado de conectividade.
  /// Retorna `true` se ao menos uma interface está ativa no momento.
  static Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
