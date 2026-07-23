import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAu3PfiGZybFtPwWZ_TYSGgQ4RhhExQcng',
    appId: '1:882802238602:web:placeholder',
    messagingSenderId: '882802238602',
    projectId: 'music-app-52dfd',
    authDomain: 'music-app-52dfd.firebaseapp.com',
    storageBucket: 'music-app-52dfd.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAu3PfiGZybFtPwWZ_TYSGgQ4RhhExQcng',
    appId: '1:882802238602:android:51a17d6d6e542809243973',
    messagingSenderId: '882802238602',
    projectId: 'music-app-52dfd',
    storageBucket: 'music-app-52dfd.firebasestorage.app',
  );
}
