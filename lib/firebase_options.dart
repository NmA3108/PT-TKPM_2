import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Firebase options are only configured for Flutter Web.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDBEMnLhKzl-XgYQ6eyGvIgsutV8Q5jB6U',
    authDomain: 'tmdt-e5958.firebaseapp.com',
    databaseURL:
        'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'tmdt-e5958',
    storageBucket: 'tmdt-e5958.firebasestorage.app',
    messagingSenderId: '493474573518',
    appId: '1:493474573518:web:10b5f46bce26859ed1349f',
  );
}
