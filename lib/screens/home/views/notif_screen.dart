import 'package:flutter/material.dart';

import '../../../services/dogs_service.dart';
import '../../../services/rt_dogs_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  //Gets notifications
  final dogService = RTDogsService();
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Widget customBox(String title, String message, String timestamp) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(title),
    );
  }

  // Fetch notifications from Firebase
  Future<void> _fetchNotifications() async {
    //Pause for 5 seconds
    await Future.delayed(Duration(seconds: 5));
    var notificationData = await dogService.getNotifications();
    if (notificationData != null && notificationData is Map<dynamic, dynamic>) {
      setState(() {
        notifications = notificationData.entries.map((entry) {
          Map<String, dynamic> value = Map<String, dynamic>.from(entry.value);
          return {
            'id': entry.key,
            'title': value['title'] ?? 'No title',
            'message': value['message'] ?? 'No message',
            'timestamp': value['timestamp'] ?? 'No timestamp',
          };
        }).toList();
      });
      print(notifications);
    } else {
      print('No notifications found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Text(notifications.toString()),
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