import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import '../../../app.dart';
 // Import where `AppThemeMode` is defined

class SettingsPage extends StatelessWidget {
  final Function(AppThemeMode) toggleTheme; // ✅ Change to AppThemeMode

  const SettingsPage({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Choose Theme:", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => toggleTheme(AppThemeMode.light), // ✅ Light Theme
            child: const Text("Light Theme"),
          ),
          ElevatedButton(
            onPressed: () => toggleTheme(AppThemeMode.dark), // ✅ Dark Theme
            child: const Text("Dark Theme"),
          ),
          ElevatedButton(
            onPressed: () => toggleTheme(AppThemeMode.system), // ✅ System Theme
            child: const Text("System Default"),
          ),
          ElevatedButton(
            onPressed: () => toggleTheme(AppThemeMode.green), // ✅ Green Theme
            child: const Text("Green Theme"),
          ),
        ],
      ),
    );
  }
}


