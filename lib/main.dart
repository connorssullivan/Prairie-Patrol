import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'app.dart';

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
          apiKey: 'AIzaSyCGh-3Xkhn-VY3nRxxLHfBypwOvlMZp5zA',
          appId: '1:731242768427:android:f3ba289b78e4679fdca26e',
          messagingSenderId: '383665209766',
          projectId: 'prairiepatrol',
          storageBucket: 'prairiepatrol.appspot.com',
        )
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
  runApp(const MyApp());
}


