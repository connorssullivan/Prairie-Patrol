import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

import '../../../services/rt_dogs_service.dart';
import '../home widgets/dog_stat_box.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  RTDogsService dogsService = RTDogsService();
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  List<Map<String, dynamic>> _dogStats = [];
  bool _isLoading = false;
  Color _selectedColor = Colors.yellow; // Default color

  Future<void> _loadDogStats() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await dogsService.getAllDogStats();
      if (mounted) {
        setState(() {
          _dogStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dog stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNewDog() async {
    if (_rfidController.text.isEmpty || _nameController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int age = int.tryParse(_ageController.text) ?? 0;
      await dogsService.addNewDog(
        _rfidController.text,
        _nameController.text,
        age,
        _selectedColor, // Pass the selected color
      );
      
      // Clear controllers
      _rfidController.clear();
      _nameController.clear();
      _ageController.clear();
      
      // Reload the stats first
      final stats = await dogsService.getAllDogStats();
      
      if (mounted) {
        setState(() {
          _dogStats = stats;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding dog: $e')),
        );
      }
    }
  }

  void _showAddDogDialog() {
    Color selectedColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Dog'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _rfidController,
                decoration: const InputDecoration(
                  labelText: 'RFID',
                  hintText: 'Enter RFID',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter dog name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter dog age',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Color: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setPickerState) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ColorPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setPickerState(() {
                                        selectedColor = color;
                                      });
                                    },
                                    pickerAreaHeightPercent: 0.8,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    _selectedColor = selectedColor;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addNewDog();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDogStats();
  }

  @override
  void dispose() {
    _rfidController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog Stats'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dogStats.isEmpty
              ? const Center(child: Text('No dogs available.'))
              : RefreshIndicator(
                  onRefresh: _loadDogStats,
                  child: ListView.builder(
                    itemCount: _dogStats.length,
                    itemBuilder: (context, index) {
                      var dog = _dogStats[index];
                      return DogStatsBox(
                        key: ValueKey(dog['id']),
                        dogId: dog['id'],
                        onDelete: _loadDogStats,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAddDogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
