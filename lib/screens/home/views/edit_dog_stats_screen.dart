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
  String? rfid;
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
      rfid = dogStats?['rfid'];
      lastCheckup = dogStats?['lastCheckup'] != null ? DateTime.parse(dogStats!['lastCheckup']) : null;
      lastCaught = dogStats?['lastCaught'] != null ? DateTime.parse(dogStats!['lastCaught']) : null;
      healthStatus = dogStats?['healthStatus'];
      age = dogStats?['age']?.toString();
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

      Map<String, dynamic> updatedFields = {};

      if (name != null && name!.isNotEmpty) updatedFields['name'] = name;
      if (rfid != null && rfid!.isNotEmpty) updatedFields['rfid'] = rfid;
      if (lastCheckup != null) updatedFields['lastCheckup'] = lastCheckup!.toUtc().toIso8601String();
      if (lastCaught != null) updatedFields['lastCaught'] = lastCaught!.toUtc().toIso8601String();
      if (healthStatus != null && healthStatus!.isNotEmpty) updatedFields['healthStatus'] = healthStatus;
      if (age != null && age!.isNotEmpty) updatedFields['age'] = int.tryParse(age!) ?? 0;

      if (updatedFields.isNotEmpty) {
        await RTDogsService().updateDogStats(widget.dogId, updatedFields);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Dog Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (value) => name = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: rfid,
                decoration: const InputDecoration(labelText: 'RFID'),
                onSaved: (value) => rfid = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Last Check-Up'),
                controller: TextEditingController(
                  text: lastCheckup != null ? _dateFormat.format(lastCheckup!) : '',
                ),
                onTap: () => _selectDate(context, lastCheckup, (selectedDate) {
                  setState(() {
                    lastCheckup = selectedDate;
                  });
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Last Caught'),
                controller: TextEditingController(
                  text: lastCaught != null ? _dateFormat.format(lastCaught!) : '',
                ),
                onTap: () => _selectDate(context, lastCaught, (selectedDate) {
                  setState(() {
                    lastCaught = selectedDate;
                  });
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: healthStatus,
                decoration: const InputDecoration(labelText: 'Health Status'),
                onSaved: (value) => healthStatus = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: age,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (value) => age = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStats,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
