import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart'; // Import the LoginPage
import 'package:prairiepatrol/screens/home/views/splash_screen.dart';
import 'skeleton.dart'; // Import the Skeleton widget
class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  _MyAppViewState createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  bool _isLoggedIn = false; // Track login status
  bool _showSplashScreen = true; // Track splash screen visibility

  @override
  void initState() {
    super.initState();

    // Show splash screen for 5 seconds and then show login or main content
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showSplashScreen = false; // Hide splash screen after 5 seconds
      });
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
          ? const SplashScreen() // Show splash screen for 5 seconds
          : _isLoggedIn
          ? const Skeleton() // Main app content when logged in
          : LoginPage(onLogin: _login), // Login page when not logged in
    );
  }
}
