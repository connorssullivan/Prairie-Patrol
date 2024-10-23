import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart'; // Import the LoginPage
import 'skeleton.dart'; // Import the Skeleton widget

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  _MyAppViewState createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  bool _isLoggedIn = false; // Track login status

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
      home: _isLoggedIn ? const Skeleton() : LoginPage(onLogin: _login), // Show LoginPage or Skeleton based on login status
    );
  }
}
