import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: const Text('Notification Screen'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate back to HomeScreen
          Navigator.pop(context);
        },
        tooltip: 'Go Back to Home',
        child: const Icon(Icons.home),
      ),
    );
  }
}