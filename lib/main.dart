import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: Allow upside-down portrait
  ]);
  try {
  if (Firebase.apps.isEmpty) {
    print('Firebase Initalizing');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.config['apiKey']!,
        appId: FirebaseConfig.config['appId']!,
        messagingSenderId: FirebaseConfig.config['messagingSenderId']!,
        projectId: FirebaseConfig.config['projectId']!,
        storageBucket: FirebaseConfig.config['storageBucket']!,
      ),
    );
  }else{
    print('Firebase already Initalized');
  }
  } catch (e) {
    if (e.toString().contains('[core/duplicate-app]')) {
      print('Firebase app already exists');
    } else {
      print('Error initializing Firebase: $e');
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Handling a background message: ${message.messageId}');
}


