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

  // This is your correct Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCbYSrunJlZeeLEy38li1fYhfxS8jnpWtc",
    authDomain: "coachfitness676767.firebaseapp.com",
    projectId: "coachfitness676767",
    storageBucket: "coachfitness676767.firebasestorage.app",
    messagingSenderId: "68239638907",
    appId: "1:68239638907:web:80b922c713c5f56c577dde",
    measurementId: "G-H5QM1W45WM",
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