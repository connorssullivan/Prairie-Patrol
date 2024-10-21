import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/dogs_service.dart';
import '../home widgets/dog_stat_box.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DogsService dogsService = DogsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Stats'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dogsService.getAllDogStats(), // Fetching data from Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loader while fetching data
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching stats: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stats available.'));
          } else {
            List<Map<String, dynamic>> dogStats = snapshot.data!;
            print(dogStats);

            return ListView.builder(
              itemCount: dogStats.length,
              itemBuilder: (context, index) {
                var dog = dogStats[index];
                return DogStatsBox(dogId: dog['id']); // Pass the dog ID to DogStatsBox
              },
            );
          }
        },
      ),
    );
  }
}