import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import 'dart:async';

import 'app.dart';

// Global variable to track initialization state
bool _firebaseInitialized = false;

Future<void> initializeFirebase() async {
  if (_firebaseInitialized) return;

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC9cgUKU4qYMaC86MGTTRIr2Hw1lpqhU1Y",
        authDomain: "prairiepatrol.firebaseapp.com",
        databaseURL: "https://prairiepatrol-default-rtdb.firebaseio.com",
        projectId: "prairiepatrol",
        storageBucket: "prairiepatrol.firebasestorage.app",
        messagingSenderId: "731242768427",
        appId: "1:731242768427:web:e889405409dda52edca26e",
        measurementId: "G-F01VBL8JS0",
      ),
    );
    _firebaseInitialized = true;
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    rethrow;
  }
}

Future<void> ensureFirebaseInitialized() async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
    return;
  }

  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    try {
      if (!_firebaseInitialized) {
        await initializeFirebase();
      }
      return;
    } catch (e) {
      attempts++;
      if (attempts == maxAttempts) {
        throw Exception('Failed to initialize Firebase after $maxAttempts attempts');
      }
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
}

void main() async {
  print('🚀 Starting application initialization');
  
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  print('📱 Device orientation set to portrait');

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialized');

  if (kIsWeb) {
    print('🌐 Running on web platform');
    // Clear any existing Firebase state in localStorage
    html.window.localStorage.remove('firebaseInitialized');
    html.window.localStorage.remove('firebaseError');
    
    // Wait for the page to be fully loaded
    await Future.delayed(const Duration(seconds: 1));
  }

  try {
    print('🔥 Initializing Firebase...');
    await ensureFirebaseInitialized();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Firebase: $e');
    // Continue with the app, as some features might still work without Firebase
  }

  // Initialize background message handler only for non-web platforms
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  print('🎉 Starting app...');
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}


