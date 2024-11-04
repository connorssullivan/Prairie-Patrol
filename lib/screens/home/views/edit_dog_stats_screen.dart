import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../../services/rt_dogs_service.dart';

class EditDogStatsScreen extends StatefulWidget {
  final String dogId;

  const EditDogStatsScreen({required this.dogId, Key? key}) : super(key: key);

  @override
  _EditDogStatsScreenState createState() => _EditDogStatsScreenState();
}

class _EditDogStatsScreenState extends State<EditDogStatsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  DateTime? lastCheckup;
  DateTime? lastCaught;
  String? healthStatus;
  String? age;

  final DateFormat _dateFormat = DateFormat.yMMMMd(); // Display format

  @override
  void initState() {
    super.initState();
    _fetchDogStats();
  }

  Future<void> _fetchDogStats() async {
    var dogStats = await RTDogsService().getDogStatsById(widget.dogId);
    setState(() {
      name = dogStats?['name'];
      lastCheckup = dogStats?['lastCheckup'] != null ? DateTime.parse(dogStats!['lastCheckup']) : null;
      lastCaught = dogStats?['lastCaught'] != null ? DateTime.parse(dogStats!['lastCaught']) : null;
      healthStatus = dogStats?['healthStatus'];
      age = dogStats?['age'];
    });
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueSetter<DateTime?> onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateSelected(picked);
  }

  Future<void> _saveStats() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create a map to hold only the fields that are not null or empty
      Map<String, dynamic> updatedFields = {};

      if (name != null && name!.isNotEmpty) updatedFields['name'] = name;
      if (lastCheckup != null) updatedFields['lastCheckup'] = lastCheckup!.toUtc().toIso8601String();
      if (lastCaught != null) updatedFields['lastCaught'] = lastCaught!.toUtc().toIso8601String();
      if (healthStatus != null && healthStatus!.isNotEmpty) updatedFields['healthStatus'] = healthStatus;
      if (age != null && age!.isNotEmpty) updatedFields['age'] = age;

      // Only call update if there are changes to make
      if (updatedFields.isNotEmpty) {
        await RTDogsService().updateDogStats(widget.dogId, updatedFields);
        Navigator.pop(context, true); // Indicate that an update was made
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Dog Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (value) => name = value,
              ),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(labelText: 'Last Check-Up'),
                controller: TextEditingController(
                  text: lastCheckup != null ? _dateFormat.format(lastCheckup!) : '',
                ),
                onTap: () => _selectDate(context, lastCheckup, (selectedDate) {
                  setState(() {
                    lastCheckup = selectedDate;
                  });
                }),
              ),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(labelText: 'Last Caught'),
                controller: TextEditingController(
                  text: lastCaught != null ? _dateFormat.format(lastCaught!) : '',
                ),
                onTap: () => _selectDate(context, lastCaught, (selectedDate) {
                  setState(() {
                    lastCaught = selectedDate;
                  });
                }),
              ),
              TextFormField(
                initialValue: healthStatus,
                decoration: InputDecoration(labelText: 'Health Status'),
                onSaved: (value) => healthStatus = value,
              ),
              TextFormField(
                initialValue: age,
                decoration: InputDecoration(labelText: 'Age'),
                onSaved: (value) => age = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStats,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
