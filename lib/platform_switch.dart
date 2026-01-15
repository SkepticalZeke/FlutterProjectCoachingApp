import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';

class PlatformSwitch {
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

  // ⭐️ FIX: Added placeholder for ANDROID
  // This allows the app to compile on mobile
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY', // Placeholder
    appId: 'YOUR_APP_ID', // Placeholder
    messagingSenderId: 'YOUR_SENDER_ID', // Placeholder
    projectId: 'coachfitness676767',
    storageBucket: 'coachfitness676767.firebasestorage.app',
  );

  // ⭐️ FIX: Added placeholder for IOS
  // This allows the app to compile on mobile
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY', // Placeholder
    appId: 'YOUR_APP_ID', // Placeholder
    messagingSenderId: 'YOUR_SENDER_ID', // Placeholder
    projectId: 'coachfitness676767',
    storageBucket: 'coachfitness676767.firebasestorage.app',
    iosBundleId: 'com.example.coachFitnessApp', // Placeholder
  );
}