// ARQUIVO GERADO AUTOMATICAMENTE pelo FlutterFire CLI.
// Execute: flutterfire configure
// Este arquivo será gerado automaticamente quando você configurar o Firebase.
// NÃO edite manualmente — execute o comando acima.

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não suporta esta plataforma.',
        );
    }
  }

  // SUBSTITUA PELOS SEUS VALORES DO FIREBASE CONSOLE
  // Após executar: flutterfire configure
  // Esse arquivo será gerado automaticamente com os valores corretos.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB13bJukRLleWGMmh1Mb2ATy8KCByr5tgs',
    appId: '1:1084562950869:android:ad38a667820f601c37305c',
    messagingSenderId: '1084562950869',
    projectId: 'voz-contra-o-fogo',
    storageBucket: 'voz-contra-o-fogo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUA_API_KEY_IOS',
    appId: 'SEU_APP_ID_IOS',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.vozContraOFogo',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_API_KEY_WEB',
    appId: 'SEU_APP_ID_WEB',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'SUA_API_KEY_MACOS',
    appId: 'SEU_APP_ID_MACOS',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.vozContraOFogo',
  );
}