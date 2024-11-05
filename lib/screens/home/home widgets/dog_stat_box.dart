import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/home/views/edit_dog_stats_screen.dart';
import '../../../services/rt_dogs_service.dart';

class DogStatsBox extends StatefulWidget {
  final String dogId;

  const DogStatsBox({required this.dogId, Key? key}) : super(key: key);

  @override
  _DogStatsBoxState createState() => _DogStatsBoxState();
}

class _DogStatsBoxState extends State<DogStatsBox> {
  Future<Map<String, dynamic>?>? _dogStats;

  @override
  void initState() {
    super.initState();
    _dogStats = _fetchDogStats();
  }

  Future<Map<String, dynamic>?> _fetchDogStats() async {
    return await RTDogsService().getDogStatsById(widget.dogId);
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat.yMMMMd().format(dateTime);
  }

  String _getDogImage(String? name) {
    if (name != null && name.toLowerCase() == 'red') {
      return 'assets/images/red_dog.png';
    } else {
      return 'assets/images/yellow_dog.png'; // Default to green dog image
    }
  }


  Future<void> _editDogStats(BuildContext context) async {
    // Navigate to the edit screen and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditDogStatsScreen(dogId: widget.dogId)),
    );

    // If an update was made, refresh the dog stats data
    if (result == true) {
      setState(() {
        _dogStats = _fetchDogStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dogStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching stats: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('No stats available for this dog.');
        } else {
          var dog = snapshot.data!;
          String imageUrl = _getDogImage(dog['name'] ?? 'Unknown');

          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _editDogStats(context),
                    child: Text('Edit Stats'),
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
