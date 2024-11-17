import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/rt_dogs_service.dart';
import 'notif_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RTDogsService dogsService = RTDogsService();
  Map<String, dynamic>? trappedDog;
  Timer? _timer;

  String _selectedDog = 'None';
  final List<String> _dogOptions = ['None', 'Red', 'Green'];

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
    Map<String, dynamic>? dogInTrap = await dogsService.checkDogsInTrap();
    setState(() {
      trappedDog = dogInTrap;
    });
  }

  // Function to release the trapped dog
  void _releaseDog() async {
    if (trappedDog != null) {
      await dogsService.releaseDog(trappedDog!['name']);
      setState(() {
        trappedDog = null; // Set to null after releasing the dog
      });
    }
  }

  // Function to trap a random dog
  void _trapRandomDog() async {
    await dogsService.trapRandomDog(); // Call the function to trap a random dog
    _checkForTrappedDogs(); // Check for trapped dogs after trapping
  }

  // Function to select a dog from the dropdown
  void _selectDog(String dog) async {
    await dogsService.selectDog(dog);
    print('Dog selected: $dog');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonDistance = 100.0; // Distance between the floating action buttons and the center button

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
                onChanged: (String? newValue) async {
                  setState(() {
                    _selectedDog = newValue!;
                  });
                  _selectDog(_selectedDog); // Call the function when a dog is selected
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
                trappedDog!['name'] == 'Red'
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
                backgroundColor:
                trappedDog != null ? Colors.red : Colors.grey, // Red if dog is trapped, grey if not
                minimumSize: const Size(200, 60),
              ),
              child: const Text('Release'),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Positioned FloatingActionButton for "Trap Random Dog"
          Positioned(
            left: screenWidth / 2 - buttonDistance, // Position this button on the left
            bottom: 150, // Align to the same level as the "Release" button
            child: FloatingActionButton(
              onPressed: _trapRandomDog, // Call the function to trap a random dog
              tooltip: 'Trap Random Dog',
              child: const Icon(Icons.pets), // Use an appropriate icon
            ),
          ),

          // Positioned FloatingActionButton for "Go to Notifications"
          Positioned(
            left: screenWidth / 2 + buttonDistance, // Position this button on the right
            bottom: 150, // Align to the same level as the "Release" button
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to the NotificationScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
              tooltip: 'Go to Notifications',
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
    );
  }
}


/*
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

  // Function to trap a random dog
  void _trapRandomDog() async {
    await dogsService.trapRandomDog(); // Call the function to trap a random dog
    _checkForTrappedDogs(); // Check for trapped dogs after trapping
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
      floatingActionButton: FloatingActionButton(
        onPressed: _trapRandomDog, // Call the function to trap a random dog
        tooltip: 'Trap Random Dog',
        child: const Icon(Icons.pets), // Use an appropriate icon
      ),
    );
  }
}
*/
