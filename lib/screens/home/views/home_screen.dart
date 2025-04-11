import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
  int? notificationCount;
  Timer? _timer;
  List<String> selectedDogs = [];
  List<Map<String, dynamic>> allDogs = [];

  @override
  void initState() {
    super.initState();
    _checkForTrappedDogs();
    _startPeriodicCheck();
    _checkForNotifications();
    _loadAllDogs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllDogs() async {
    try {
      DataSnapshot snapshot = await dogsService.dbRef.child('dogs').get();
      if (snapshot.exists) {
        final dogsData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          allDogs = dogsData.entries.map((entry) {
            return {
              'id': entry.key,
              'name': entry.value['name'],
              'rfid': entry.value['rfid'],
              'inTrap': entry.value['inTrap'] ?? false,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading dogs: $e');
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForTrappedDogs();
      _checkForNotifications();
      _loadAllDogs();
    });
  }

  void _checkForTrappedDogs() async {
    Map<String, dynamic>? dogInTrap = await dogsService.checkDogsInTrap();
    setState(() {
      trappedDog = dogInTrap;
    });
  }

  void _checkForNotifications() async {
    int? count = await dogsService.checkNotificationCount();
    setState(() {
      notificationCount = count;
    });
  }

  void _releaseDog() async {
    if (trappedDog != null) {
      await dogsService.releaseDog(trappedDog!['name']);
      setState(() {
        trappedDog = null;
      });
    }
  }

  void _trapRandomDog() async {
    await dogsService.trapRandomDog();
    _checkForTrappedDogs();
  }

  void _toggleDogSelection(String dogId) async {
    final dog = allDogs.firstWhere((d) => d['id'] == dogId, orElse: () => {});
    final rfid = dog['rfid'];

    if (rfid == null) return;

    setState(() {
      if (selectedDogs.contains(dogId)) {
        selectedDogs.remove(dogId);
        dogsService.removeRfidFromList(rfid); // 🗑 Remove
      } else {
        selectedDogs.add(dogId);
        dogsService.appendRfidToList(rfid);   // ➕ Add
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonDistance = 100.0;

    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Dogs:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: allDogs.map((dog) {
                      final isSelected = selectedDogs.contains(dog['id']);
                      final isInTrap = dog['inTrap'] == true;
                      
                      return GestureDetector(
                        onTap: () => _toggleDogSelection(dog['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isInTrap ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            dog['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: trappedDog != null
                  ? Image.asset(
                      'assets/images/${(trappedDog!['name']?.toLowerCase() == 'red' ? 'red' : 'yellow')}_dog.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.pets,
                          size: 100,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Text(
                      '-',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 200),
            ElevatedButton(
              onPressed: trappedDog != null ? _releaseDog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: trappedDog != null ? Colors.red : Colors.grey,
                minimumSize: const Size(200, 60),
              ),
              child: const Text('Release'),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: screenWidth / 2 - buttonDistance,
            bottom: 150,
            child: FloatingActionButton(
              onPressed: _trapRandomDog,
              tooltip: 'Trap Random Dog',
              child: const Icon(Icons.pets),
              heroTag: 'trapRandomDog',
            ),
          ),
          Positioned(
            left: screenWidth / 2 + buttonDistance,
            bottom: 150,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationScreen()),
                    );
                  },
                  tooltip: 'Go to Notifications',
                  child: const Icon(Icons.notifications),
                ),
                if (notificationCount != null && notificationCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
