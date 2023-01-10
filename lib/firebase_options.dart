// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAhVEAiUzCJqSgayIAL4Rat5wqB7OZ-r-4',
    appId: '1:461906582742:web:7a22529bf5fc3b6fdafd77',
    messagingSenderId: '461906582742',
    projectId: 'karma-palace',
    authDomain: 'karma-palace.firebaseapp.com',
    databaseURL: 'https://karma-palace-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'karma-palace.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBivBkqg_q8wknd1sVaag_IJPxf3N27jO4',
    appId: '1:461906582742:android:0ffe43d19048602fdafd77',
    messagingSenderId: '461906582742',
    projectId: 'karma-palace',
    databaseURL: 'https://karma-palace-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'karma-palace.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNZv8KREbVO_tEhWi4DTETQHxri-ECe1Q',
    appId: '1:461906582742:ios:e9e743fa9b6fc034dafd77',
    messagingSenderId: '461906582742',
    projectId: 'karma-palace',
    databaseURL: 'https://karma-palace-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'karma-palace.appspot.com',
    iosClientId: '461906582742-c0pip9cfn2nstg8j1bm4muo7j7elvb9e.apps.googleusercontent.com',
    iosBundleId: 'com.nathanodong.karmaPalace',
  );
}