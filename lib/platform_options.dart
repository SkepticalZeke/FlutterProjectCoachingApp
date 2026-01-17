import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class PlatformSwitchOptions {
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

  // This is your correct Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB0cy2Ss1f5jSsvoSeTA8sXi-0jGP_oVK0",
    authDomain: "fitness-coaching-app-5633f.firebaseapp.com",
    projectId: "fitness-coaching-app-5633f",
    storageBucket: "fitness-coaching-app-5633f.firebasestorage.app",
    messagingSenderId: "150046979522",
    appId: "1:150046979522:web:93a562a09cda9ed6d7925b",
    measurementId: "G-TYV1NY9Z02"
  );

  // ⭐️ ANDROID Configuration
  // These values should match your Firebase project
  // Get these from Firebase Console > Project Settings > Service Accounts > Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0cy2Ss1f5jSsvoSeTA8sXi-0jGP_oVK0', // From google-services.json or Firebase Console
    appId: '1:150046979522:android:93a562a09cda9ed6d7925b', // Replace with actual Android App ID
    messagingSenderId: '150046979522',
    projectId: 'fitness-coaching-app-5633f',
    storageBucket: 'fitness-coaching-app-5633f.firebasestorage.app',
  );

  // ⭐️ iOS Configuration
  // These values should match your Firebase project
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0cy2Ss1f5jSsvoSeTA8sXi-0jGP_oVK0',
    appId: '1:150046979522:ios:93a562a09cda9ed6d7925b', // Replace with actual iOS App ID
    messagingSenderId: '150046979522',
    projectId: 'fitness-coaching-app-5633f',
    storageBucket: 'fitness-coaching-app-5633f.firebasestorage.app',
    iosBundleId: 'com.example.coachFitnessApp',
  );
}