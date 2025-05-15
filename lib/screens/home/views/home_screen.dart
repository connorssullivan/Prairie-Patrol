import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/rt_dogs_service.dart';
import '../../../services/admin_service.dart';
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
  List<String> selectedRfids = [];
  StreamSubscription? _rfidSubscription;
  StreamSubscription? _caughtDogSubscription;
  String? caughtDogRfid;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
    _checkForNotifications();
    _loadAllDogs();
    _listenToSelectedRfids();
    _listenToCaughtDog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rfidSubscription?.cancel();
    _caughtDogSubscription?.cancel();
    super.dispose();
  }

  void _listenToCaughtDog() {
    _caughtDogSubscription = dogsService.dbRef.child('caughtDog').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          caughtDogRfid = event.snapshot.value.toString();
          _updateTrappedDog();
        });
      } else {
        setState(() {
          caughtDogRfid = null;
          trappedDog = null;
        });
      }
    });
  }

  void _updateTrappedDog() {
    if (caughtDogRfid != null) {
      final dog = allDogs.firstWhere(
        (d) => d['rfid'] == caughtDogRfid,
        orElse: () => {},
      );
      if (dog.isNotEmpty) {
        setState(() {
          trappedDog = dog;
        });
      }
    }
  }

  void _listenToSelectedRfids() {
    _rfidSubscription = dogsService.dbRef.child('selectedDog/listRfid').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        if (event.snapshot.value is List) {
          List list = event.snapshot.value as List;
          setState(() {
            selectedRfids = list.where((item) => item != null).map((item) => item.toString()).toList();
          });
        } else if (event.snapshot.value is Map) {
          Map map = event.snapshot.value as Map;
          setState(() {
            selectedRfids = map.values.where((item) => item != null).map((item) => item.toString()).toList();
          });
        }
      } else {
        setState(() {
          selectedRfids = [];
        });
      }
    });
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForNotifications();
      _loadAllDogs();
    });
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
              'name': entry.value['name'] ?? 'UnnamedDog',
              'rfid': entry.value['rfid'] ?? 'UnknownRFID',
              'inTrap': entry.value['inTrap'] ?? false,
              'color': entry.value['color'],
            };
          }).toList();
          _updateTrappedDog();
        });
      }
    } catch (e) {
      print('Error loading dogs: $e');
    }
  }

  void _checkForNotifications() async {
    try {
      int? count = await dogsService.checkNotificationCount();
      if (mounted) {
        setState(() {
          notificationCount = count;
        });
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  void _releaseDog() async {
    if (trappedDog != null) {
      await dogsService.releaseDog(trappedDog!['name']);
      await dogsService.dbRef.child('caughtDog').set('');
      setState(() {
        trappedDog = null;
      });
    }
  }

  void _trapRandomDog() async {
    await dogsService.trapRandomDog();
    _checkForNotifications();
    _loadAllDogs();
  }

  void _toggleDogSelection(String dogId) async {
    final dog = allDogs.firstWhere((d) => d['id'] == dogId, orElse: () => {});
    final rfid = dog['rfid'];

    if (rfid == null) return;

    setState(() {
      if (selectedRfids.contains(rfid)) {
        selectedRfids.remove(rfid);
        dogsService.removeRfidFromList(rfid);
      } else {
        selectedRfids.add(rfid);
        dogsService.appendRfidToList(rfid);
      }
    });
  }

  Color _getDogColor(String? name, dynamic colorValue) {
    if (colorValue != null) {
      try {
        // Handle string color values
        if (colorValue is String) {
          // Try to parse as hex color
          if (colorValue.startsWith('0x')) {
            return Color(int.parse(colorValue));
          } else if (colorValue.startsWith('#')) {
            return Color(int.parse(colorValue.replaceAll('#', '0x')));
          }
          // Try to parse as named color
          switch (colorValue.toLowerCase()) {
            case 'red':
              return Colors.red;
            case 'yellow':
              return Colors.yellow;
            default:
              return Colors.yellow;
          }
        }
        // Handle numeric color values
        else if (colorValue is int) {
          return Color(colorValue);
        }
        // Handle Firebase Value objects
        else if (colorValue is Map) {
          final value = colorValue['value'];
          if (value is String && value.startsWith('0x')) {
            return Color(int.parse(value));
          } else if (value is int) {
            return Color(value);
          }
        }
      } catch (e) {
        print('Error parsing color: $e');
      }
    }
    return Colors.yellow;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonDistance = 100.0;
    final isAdmin = AdminService.isAdmin();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
                              final isSelected = selectedRfids.contains(dog['rfid']);
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
                    const SizedBox(height: 20),
                    Center(
                      child: trappedDog != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    _getDogColor(trappedDog!['name'], trappedDog!['color']).withOpacity(1.0),
                                    BlendMode.modulate,
                                  ),
                                  child: Image.asset(
                                    'assets/images/base_dog.png',
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getDogColor(trappedDog!['name'], trappedDog!['color']),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300, width: 2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  trappedDog!['name'] ?? 'Unknown Dog',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              '-',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Place the floating action buttons above the Release button
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAdmin)
                    FloatingActionButton(
                      onPressed: _trapRandomDog,
                      tooltip: 'Trap Random Dog',
                      child: const Icon(Icons.pets),
                      heroTag: 'trapRandomDog',
                    ),
                  if (isAdmin)
                    const SizedBox(width: 50),
                  Stack(
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: trappedDog != null ? _releaseDog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: trappedDog != null ? Colors.red : Colors.grey,
                  minimumSize: const Size(200, 60),
                ),
                child: const Text('Release'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
