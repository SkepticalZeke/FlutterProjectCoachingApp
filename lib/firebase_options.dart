import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android; // This will no longer cause an error
      case TargetPlatform.iOS:
        return ios; // This will no longer cause an error
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Updated Web config for new project: fitness-coaching-app-5633f
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCbYSrunJlZeeLEy38li1fYhfxS8jnpWtc",
    authDomain: "fitness-coaching-app-5633f.firebaseapp.com",
    projectId: "fitness-coaching-app-5633f",
    storageBucket: "fitness-coaching-app-5633f.firebasestorage.app",
    messagingSenderId: "68239638907",
    appId: "1:68239638907:web:80b922c713c5f56c577dde",
    measurementId: "G-H5QM1W45WM",
  );

  // Android config for new project: fitness-coaching-app-5633f
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9ZzX_-UJsBXDd_gqc-GT5xUfNsYMPubk',
    appId: '1:150046979522:android:cd190498f42b8aa4d7925b',
    messagingSenderId: '150046979522',
    projectId: 'fitness-coaching-app-5633f',
    storageBucket: 'fitness-coaching-app-5633f.firebasestorage.app',
  );

  // iOS config for new project: fitness-coaching-app-5633f
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY', // TODO: Replace with actual iOS API key
    appId: 'YOUR_APP_ID', // TODO: Replace with actual iOS app ID
    messagingSenderId: 'YOUR_SENDER_ID', // TODO: Replace with actual sender ID
    projectId: 'fitness-coaching-app-5633f',
    storageBucket: 'fitness-coaching-app-5633f.firebasestorage.app',
    iosBundleId: 'com.example.coachFitnessApp', // TODO: Replace with actual bundle ID
  );
}