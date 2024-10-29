import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart'; // Import the LoginPage
import 'skeleton.dart'; // Import the Skeleton widget
import 'package:prairiepatrol/screens/home/views/splash_screen.dart'; // Import the SplashScreen

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

    // Delayed navigation to ensure context is valid after the state update
    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushReplacementNamed('/home');
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
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => Skeleton(),
      },
    );
  }
}
