import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../screens/home/views/edit_dog_stats_screen.dart';
import '../../../services/rt_dogs_service.dart';

class DogStatsBox extends StatefulWidget {
  final String dogId;
  final VoidCallback? onDelete;

  const DogStatsBox({
    required this.dogId,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  _DogStatsBoxState createState() => _DogStatsBoxState();
}

class _DogStatsBoxState extends State<DogStatsBox> {
  Future<Map<String, dynamic>?>? _dogStats;
  final TextEditingController _rfidController = TextEditingController();
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _dogStats = _fetchDogStats();
  }

  Future<Map<String, dynamic>?> _fetchDogStats() async {
    if (_isDeleted) return null;
    return await RTDogsService().getDogStatsById(widget.dogId);
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'N/A';
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat.yMMMMd().format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  String _getDogImage(String? name) {
    return 'assets/images/base_dog.png';
  }

  Color _getDogColor(String? name, String? colorHex) {
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        // Try to parse as hex color
        if (colorHex.startsWith('0x')) {
          return Color(int.parse(colorHex));
        } else if (colorHex.startsWith('#')) {
          return Color(int.parse(colorHex.replaceAll('#', '0x')));
        }
        // Try to parse as named color
        switch (colorHex.toLowerCase()) {
          case 'red':
            return Colors.red;
          case 'yellow':
            return Colors.yellow;
          default:
            return Colors.yellow;
        }
      } catch (e) {
        print('Error parsing color: $e');
        return Colors.yellow;
      }
    }
    return Colors.yellow;
  }

  Future<void> _editDogStats(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditDogStatsScreen(dogId: widget.dogId)),
    );

    if (result == true) {
      setState(() {
        _dogStats = _fetchDogStats();
      });
    }
  }

  Future<void> _editRFID(BuildContext context, String currentRFID) async {
    _rfidController.text = currentRFID;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit RFID'),
        content: TextField(
          controller: _rfidController,
          decoration: const InputDecoration(
            labelText: 'RFID',
            hintText: 'Enter new RFID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && _rfidController.text.isNotEmpty) {
      try {
        await RTDogsService().updateDogStats(widget.dogId, {'rfid': _rfidController.text});
        setState(() {
          _dogStats = _fetchDogStats();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('RFID updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating RFID: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteDog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dog'),
        content: const Text('Are you sure you want to delete this dog? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RTDogsService().deleteDog(widget.dogId);
        if (mounted) {
          setState(() {
            _isDeleted = true;
          });
          widget.onDelete?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dog deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting dog: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _rfidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _dogStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching stats: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Text('No stats available for this dog.');
        } else {
          var dog = snapshot.data!;
          String imageUrl = _getDogImage(dog['name'] ?? 'Unknown');

          return Card(
            margin: const EdgeInsets.all(10),
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
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              _getDogColor(dog['name'], dog['color']).withOpacity(1.0),
                              BlendMode.modulate,
                            ),
                            child: Image.asset(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Name: ${dog['name'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDog(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text('RFID: ${dog['rfid'] ?? 'N/A'}'),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _editRFID(context, dog['rfid'] ?? ''),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Last Check-Up: ${_formatTimestamp(dog['lastCheckup'])}'),
                            Text('Last Caught: ${_formatTimestamp(dog['lastCaught'])}'),
                            Text('Health Status: ${dog['healthStatus'] ?? 'N/A'}'),
                            Text('Age: ${dog['age'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _editDogStats(context),
                    child: const Text('Edit All Stats'),
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
