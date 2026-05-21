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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAJLgSCk3iNvQ4ancUUpo9FixYYyLOop2o',
    appId: '1:15875695920:web:55441177fcdf48868ed4f5',
    messagingSenderId: '15875695920',
    projectId: 'jaktimer-f423f',
    authDomain: 'jaktimer-f423f.firebaseapp.com',
    storageBucket: 'jaktimer-f423f.firebasestorage.app',
    measurementId: 'G-66D0R9YTBE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTZLDIuMDIAh6umX9b09Z0boi1-B-DQXI',
    appId: '1:15875695920:android:bb474f043684bc9e8ed4f5',
    messagingSenderId: '15875695920',
    projectId: 'jaktimer-f423f',
    storageBucket: 'jaktimer-f423f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCp87jyMpotGA7lCed2hylEBYAXo7r1ZgY',
    appId: '1:15875695920:ios:893a33cb171fa5648ed4f5',
    messagingSenderId: '15875695920',
    projectId: 'jaktimer-f423f',
    storageBucket: 'jaktimer-f423f.firebasestorage.app',
    iosBundleId: 'com.example.jaktimerApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCp87jyMpotGA7lCed2hylEBYAXo7r1ZgY',
    appId: '1:15875695920:ios:893a33cb171fa5648ed4f5',
    messagingSenderId: '15875695920',
    projectId: 'jaktimer-f423f',
    storageBucket: 'jaktimer-f423f.firebasestorage.app',
    iosBundleId: 'com.example.jaktimerApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAJLgSCk3iNvQ4ancUUpo9FixYYyLOop2o',
    appId: '1:15875695920:web:33430382b67f6e378ed4f5',
    messagingSenderId: '15875695920',
    projectId: 'jaktimer-f423f',
    authDomain: 'jaktimer-f423f.firebaseapp.com',
    storageBucket: 'jaktimer-f423f.firebasestorage.app',
    measurementId: 'G-XL848Y21MH',
  );
}
