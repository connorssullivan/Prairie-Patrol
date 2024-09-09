import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/dogs_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DogsService dogsService = DogsService();

  // Function to format the Firestore timestamp into a readable date
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dateTime = timestamp.toDate(); // Convert to DateTime
    return DateFormat.yMMMMd().format(dateTime); // Format the date
  }

  Future<List<Map<String, dynamic>>> _fetchDogStats() async {
    return await dogsService.getAllDogStats(); // Fetching data from Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Stats'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDogStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loader while fetching data
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching stats: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stats available.'));
          } else {
            List<Map<String, dynamic>> dogStats = snapshot.data!;

            return ListView.builder(
              itemCount: dogStats.length,
              itemBuilder: (context, index) {
                var dog = dogStats[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${dog['name']}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('Last Check-Up: ${_formatTimestamp(dog['lastCheckup'])}'),
                        Text('Last Caught: ${_formatTimestamp(dog['lastCaught'])}'),
                        Text('Health Status: ${dog['healthStatus'] ?? 'N/A'}'),
                        Text('Age: ${dog['age'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}