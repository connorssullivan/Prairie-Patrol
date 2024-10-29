import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 10), () { // Increase the duration to 10 seconds
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/zoo_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight, // Align the image to the right
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/zoo_logo.png', height: 100),
              SizedBox(height: 20),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green, // Green background
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black), // Black color
                    backgroundColor: Colors.green, // Green background
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
