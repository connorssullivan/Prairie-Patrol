import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/services/dogs_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DogsService dogsService = DogsService();
  DocumentSnapshot? trappedDog;
  Timer? _timer;

  String _selectedDog = 'None';

  final List<String> _dogOptions = ['None', 'Red Dog', 'Yellow Dog'];

  @override
  void initState() {
    super.initState();
    _checkForTrappedDogs(); // Initial check for trapped dogs
    _startPeriodicCheck();  // Start periodic check
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Function to start a periodic check for dogs in the trap
  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkForTrappedDogs(); // Check every 5 seconds
    });
  }

  // Function to check for dogs in the trap
  void _checkForTrappedDogs() async {
    DocumentSnapshot? dogInTrap = await dogsService.checkDogsInTrap();
    setState(() {
      trappedDog = dogInTrap;
    });
  }

  // Function to release the trapped dog
  void _releaseDog() async {
    if (trappedDog != null) {
      await dogsService.releaseDog(trappedDog!.id);
      setState(() {
        trappedDog = null; // Set to null after releasing the dog
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: DropdownButton<String>(
                value: _selectedDog, // Currently selected value
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.blue),
                underline: Container(
                  height: 2,
                  color: Colors.blueAccent,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDog = newValue!;
                  });
                },
                items: _dogOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 50),

            // Display the trapped dog or a dash if none is trapped
            Center(
              child: trappedDog != null
                  ? Image.asset(
                trappedDog!['color'] == 'red'
                    ? 'assets/images/red_dog.png'
                    : 'assets/images/yellow_dog.png',
                width: 200, // Adjust the size as needed
                height: 200,
                fit: BoxFit.contain,
              )
                  : const Text(
                '-',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 200),
            ElevatedButton(
              onPressed: trappedDog != null
                  ? () {
                _releaseDog(); // Call the release dog function
              }
                  : null, // Disable button if no dog is trapped
              style: ElevatedButton.styleFrom(
                backgroundColor: trappedDog != null ? Colors.red : Colors.grey, // Red if dog is trapped, grey if not
                minimumSize: const Size(200, 60),
              ),
              child: const Text('Release'),
            ),
          ],
        ),
      ),
    );
  }
}
