import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDcdKsmOO1xzkcj0YAGpjOIWhWwfYnUe30',
    authDomain: 'ceremonial-ledger.firebaseapp.com',
    projectId: 'ceremonial-ledger',
    storageBucket: 'ceremonial-ledger.firebasestorage.app',
    messagingSenderId: '561456351283',
    appId: '1:561456351283:web:b85d0fe40020a66c497b46',
    measurementId: 'G-3TP0LXGPKE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcdKsmOO1xzkcj0YAGpjOIWhWwfYnUe30',
    authDomain: 'ceremonial-ledger.firebaseapp.com',
    projectId: 'ceremonial-ledger',
    storageBucket: 'ceremonial-ledger.firebasestorage.app',
    messagingSenderId: '561456351283',
    appId: '1:561456351283:android:705a372f08d508dc497b46',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDcdKsmOO1xzkcj0YAGpjOIWhWwfYnUe30',
    authDomain: 'ceremonial-ledger.firebaseapp.com',
    projectId: 'ceremonial-ledger',
    storageBucket: 'ceremonial-ledger.firebasestorage.app',
    messagingSenderId: '561456351283',
    appId: '1:561456351283:ios:1:561456351283:ios:06a65f64f40fcaa3497b46',
    iosBundleId: 'com.yourcompany.ceremonialLedger',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDcdKsmOO1xzkcj0YAGpjOIWhWwfYnUe30',
    authDomain: 'ceremonial-ledger.firebaseapp.com',
    projectId: 'ceremonial-ledger',
    storageBucket: 'ceremonial-ledger.firebasestorage.app',
    messagingSenderId: '561456351283',
    appId: '1:561456351283:ios:1:561456351283:ios:06a65f64f40fcaa3497b46',
    iosBundleId: 'com.yourcompany.ceremonialLedger',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDcdKsmOO1xzkcj0YAGpjOIWhWwfYnUe30',
    authDomain: 'ceremonial-ledger.firebaseapp.com',
    projectId: 'ceremonial-ledger',
    storageBucket: 'ceremonial-ledger.firebasestorage.app',
    messagingSenderId: '561456351283',
    appId: '1:561456351283:web:b85d0fe40020a66c497b46',
  );
}
