import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ SharedPrefs (optional to await unless needed before runApp)
  await SharedPreferences.getInstance();

  try {
    if (Firebase.apps.isEmpty) {
      print('Firebase Initializing...');

      await Firebase.initializeApp(
        options: kIsWeb
            ? const FirebaseOptions(
          apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
          authDomain: "prairiepatrol.firebaseapp.com",
          databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
          projectId: "prairiepatrol",
          storageBucket: "prairiepatrol.firebasestorage.app",
          messagingSenderId: "731242768427",
          appId: "1:731242768427:web:e889405409dda52edca26e",
          measurementId: "G-F01VBL8JS0",
        )
            : null, // ✅ Android/iOS use native google-services.json & .plist
      );
    }
  } catch (e) {
    if (e.toString().contains('[core/duplicate-app]')) {
      print('Firebase already initialized.');
    } else {
      print('Firebase init error: $e');
    }
  }

  // ✅ Background message handler (no-op on web)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Handling a background message: ${message.messageId}');
}


