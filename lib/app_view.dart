import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart'; // Import the LoginPage
import 'package:prairiepatrol/screens/home/views/splash_screen.dart';
import 'skeleton.dart'; // Import the Skeleton widget
import 'package:firebase_auth/firebase_auth.dart';


class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  _MyAppViewState createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  bool _showSplashScreen = true; // Track splash screen visibility
  bool _isLoggedIn = false; // Track login status

  @override
  void initState() {
    super.initState();

    // Show splash screen for 5 seconds, then check login status
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showSplashScreen = false; // Hide splash screen after 5 seconds
      });
      requestPermission();
      _checkLoginStatus();
    });
  }

  void _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null; // If user is not null, they are logged in
    });
  }

  void _login() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prairie Patrol',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          onSurface: Colors.black,
          primary: Color(0xFF00B2E7),
          secondary: Color(0xFFE064F7),
          tertiary: Color(0xFFFF8D6C),
          outline: Colors.grey,
        ),
      ),
      home: _showSplashScreen
          ? const SplashScreen() // Show splash screen
          : _isLoggedIn
          ? const Skeleton() // Main app content when logged in
          : LoginPage(onLogin: _login), // Login page when not logged in
    );
  }

  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not granted permission');
      return;
    }

    // Attempt to retrieve APNs token
    try {
      String? apnsToken = await messaging.getAPNSToken();
      print('APNs Token: $apnsToken');
      if (apnsToken == null) {
        print('APNs token is still null.');
      }
    } catch (e) {
      print('Error retrieving APNs Token: $e');
    }

    // Retrieve FCM token
    try {
      String? fcmToken = await messaging.getToken();
      print('FCM Token: $fcmToken');
    } catch (e) {
      print('Error retrieving FCM Token: $e');
    }
  }

}
