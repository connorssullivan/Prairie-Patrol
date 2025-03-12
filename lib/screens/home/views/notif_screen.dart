import 'package:flutter/material.dart';
import '../../../services/rt_dogs_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final dogService = RTDogsService();
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Converts timestamp to readable format
  String formatTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal().toString();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return 'No timestamp';
    }
  }

  // Custom notification widget
  Widget customBox(String title, String message, dynamic timestamp, String id) {
    String formattedTimestamp = formatTimestamp(timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Notification Title
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Delete individual notification button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await dogService.deleteNotification(id);
                    _fetchNotifications(); // Refresh notifications instantly
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 5),
            Text(
              formattedTimestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch notifications from Firebase
  Future<void> _fetchNotifications() async {
    var notificationData = await dogService.getNotifications();
    setState(() {
      if (notificationData != null && notificationData is Map<dynamic, dynamic>) {
        notifications = notificationData.entries.map((entry) {
          Map<String, dynamic> value = Map<String, dynamic>.from(entry.value);
          return {
            'id': entry.key,
            'title': value['title'] ?? 'No title',
            'message': value['message'] ?? 'No message',
            'timestamp': value['timestamp'] ?? 'No timestamp',
          };
        }).toList();

        // Sort notifications (newest first)
        notifications.sort((a, b) {
          var timestampA = a['timestamp'];
          var timestampB = b['timestamp'];

          if (timestampA is int && timestampB is int) {
            return timestampB.compareTo(timestampA);
          } else if (timestampA is String && timestampB is String) {
            return timestampB.compareTo(timestampA);
          } else {
            return 0;
          }
        });
      } else {
        notifications.clear();
      }
    });
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    await dogService.deleteAllNotifications();
    _fetchNotifications(); // Refresh notifications instantly
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: notifications.isNotEmpty ? deleteAllNotifications : null,
                color: notifications.isNotEmpty ? Colors.white : Colors.grey,
                tooltip: 'Delete All Notifications',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: deleteAllNotifications,
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete All"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
              child: Text(
                'No notifications available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return customBox(
                  notification['title'],
                  notification['message'],
                  notification['timestamp'],
                  notification['id'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
