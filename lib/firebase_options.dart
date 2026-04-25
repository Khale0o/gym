// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Real Firebase options extracted from google-services.json.
/// Project: apex-gym-system  |  Sender: 970813086875
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  // Web / Windows share the same API key — add web app in Firebase Console
  // if you need web support.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtZRYVJE7ECqAo2iGZ59-x6gwSujDgZb8',
    appId: '1:970813086875:web:apex_gym_web',
    messagingSenderId: '970813086875',
    projectId: 'apex-gym-system',
    authDomain: 'apex-gym-system.firebaseapp.com',
    storageBucket: 'apex-gym-system.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtZRYVJE7ECqAo2iGZ59-x6gwSujDgZb8',
    appId: '1:970813086875:android:ee4a445d3eaa35c9ab7a3e',
    messagingSenderId: '970813086875',
    projectId: 'apex-gym-system',
    storageBucket: 'apex-gym-system.firebasestorage.app',
  );

  // Add iOS app in Firebase Console for real iOS values:
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtZRYVJE7ECqAo2iGZ59-x6gwSujDgZb8',
    appId: '1:970813086875:ios:apex_gym_ios',
    messagingSenderId: '970813086875',
    projectId: 'apex-gym-system',
    storageBucket: 'apex-gym-system.firebasestorage.app',
    iosBundleId: 'com.example.apexGymSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtZRYVJE7ECqAo2iGZ59-x6gwSujDgZb8',
    appId: '1:970813086875:ios:apex_gym_macos',
    messagingSenderId: '970813086875',
    projectId: 'apex-gym-system',
    storageBucket: 'apex-gym-system.firebasestorage.app',
    iosBundleId: 'com.example.apexGymSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDtZRYVJE7ECqAo2iGZ59-x6gwSujDgZb8',
    appId: '1:970813086875:web:apex_gym_windows',
    messagingSenderId: '970813086875',
    projectId: 'apex-gym-system',
    authDomain: 'apex-gym-system.firebaseapp.com',
    storageBucket: 'apex-gym-system.firebasestorage.app',
  );
}
