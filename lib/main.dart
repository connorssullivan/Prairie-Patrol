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
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyCGh-3Xkhn-VY3nRxxLHfBypwOvlMZp5zA',
        appId: '1:731242768427:android:f3ba289b78e4679fdca26e',
        messagingSenderId: '383665209766',
        projectId: 'prairiepatrol',
        storageBucket: 'prairiepatrol.appspot.com',
      )
  );
  runApp(const MyApp());
}


