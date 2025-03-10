import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart'; // Import the LoginPage
import 'package:prairiepatrol/screens/home/views/settings_page.dart';
import 'package:prairiepatrol/screens/home/views/splash_screen.dart';
import 'app.dart';
import 'skeleton.dart'; // Import the Skeleton widget
import 'package:firebase_auth/firebase_auth.dart';


class MyAppView extends StatefulWidget {
  final Function(AppThemeMode) toggleTheme; // ✅ Change to AppThemeMode

  const MyAppView({super.key, required this.toggleTheme});

  @override
  _MyAppViewState createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  bool _showSplashScreen = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showSplashScreen = false;
      });
      _checkLoginStatus();
    });
  }

  void _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplashScreen
        ? const SplashScreen()
        : _isLoggedIn
        ? Skeleton(toggleTheme: widget.toggleTheme) // ✅ Use AppThemeMode
        : LoginPage(
      onLogin: () {
        setState(() {
          _isLoggedIn = true;
        });
      },
    );
  }
}

