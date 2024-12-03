import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF84B067), // Background color #84B067
      appBar: AppBar(
        title: Text("Prairie Patrol"),
        backgroundColor: Color(0xFF84B067), // Match AppBar with background color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image in the center
            Image.asset(
              'assets/images/zoo_logo.png',
              height: 120.0, // You can adjust the size as per your needs
              width: 120.0,
            ),
            SizedBox(height: 30),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black), // White text
            ),
            SizedBox(height: 20),
            // A thinner loading bar covering the middle third
            Container(
              width: MediaQuery.of(context).size.width * 0.33, // Middle third of the screen width
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // White progress bar
                minHeight: 4.0, // Thinner progress bar
              ),
            ),
          ],
        ),
      ),
    );
  }
}