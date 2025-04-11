import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart'; // Your app widget or router

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Handling a background message: ${message.messageId}');
}

void main() async {
  print('🚀 Starting application initialization');
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  print('📱 Device orientation set to portrait');

  if (kIsWeb) {
    print('🌐 Platform is Web');

    // Wait for the JS SDK to potentially initialize Firebase
    print('⏳ Waiting 2 seconds for web platform to be ready...');
    await Future.delayed(const Duration(seconds: 2));

    try {
      bool isInitialized = false;
      int attempts = 0;
      const maxAttempts = 10;

      while (!isInitialized && attempts < maxAttempts) {
        if (html.window.localStorage.containsKey('firebaseInitialized')) {
          final state = html.window.localStorage['firebaseInitialized'];
          isInitialized = state == 'true';
          final error = html.window.localStorage['firebaseError'];
          if (error != null) {
            print('⚠️ Firebase JS SDK error: $error');
          }
        }

        if (!isInitialized) {
          attempts++;
          print('⏳ Waiting for Firebase JS SDK initialization... (attempt $attempts)');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (isInitialized) {
        print('✅ Firebase JS SDK initialized, initializing Flutter Firebase...');
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
            authDomain: "prairiepatrol.firebaseapp.com",
            databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
            projectId: "prairiepatrol",
            storageBucket: "prairiepatrol.appspot.com",
            messagingSenderId: "731242768427",
            appId: "1:731242768427:web:e889405409dda52edca26e",
            measurementId: "G-F01VBL8JS0",
          ),
        );
        print('✅ Firebase initialized successfully on Web (Flutter)');
      } else {
        throw Exception('Firebase JS SDK initialization timed out');
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing Firebase on web: $e');
      print(stackTrace);
      print('⏳ Waiting 5 seconds before final attempt...');
      await Future.delayed(const Duration(seconds: 5));
      print('🔄 Final attempt to initialize Firebase...');
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
          authDomain: "prairiepatrol.firebaseapp.com",
          databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
          projectId: "prairiepatrol",
          storageBucket: "prairiepatrol.appspot.com",
          messagingSenderId: "731242768427",
          appId: "1:731242768427:web:e889405409dda52edca26e",
          measurementId: "G-F01VBL8JS0",
        ),
      );
    }
  } else {
    print('📱 Platform is not Web, initializing Firebase directly...');
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
        authDomain: "prairiepatrol.firebaseapp.com",
        databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
        projectId: "prairiepatrol",
        storageBucket: "prairiepatrol.appspot.com",
        messagingSenderId: "731242768427",
        appId: "1:731242768427:web:e889405409dda52edca26e",
        measurementId: "G-F01VBL8JS0",
      ),
    );

    // Setup background handler only on mobile
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  print('🎉 Launching Prairie Patrol app...');
  runApp( MyApp());
}

