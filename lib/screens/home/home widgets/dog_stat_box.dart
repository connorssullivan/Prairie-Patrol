import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/dogs_service.dart';



class DogStatsBox extends StatelessWidget {
  final String dogId;

  const DogStatsBox({required this.dogId, Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dateTime = timestamp.toDate();
    return DateFormat.yMMMMd().format(dateTime);
  }

  Future<Map<String, dynamic>?> _fetchDogStats() async {
    return await DogsService().getDogStatsById(dogId);
  }

  String _getDogImage(String name) {
    // Function to return the appropriate image based on the dog's name
    if (name.toLowerCase() == 'red') {
      return 'assets/images/red_dog.png';
    } else {
      return 'assets/images/yellow_dog.png'; // Default to yellow dog image
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchDogStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching stats: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('No stats available for this dog.');
        } else {
          var dog = snapshot.data!;
          String imageUrl = _getDogImage(dog['name'] ?? 'Unknown'); // Get the image URL

          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Align to move the image down
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(imageUrl),
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${dog['name'] ?? 'N/A'}',
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
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
