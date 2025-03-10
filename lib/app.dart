import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_view.dart';

import 'package:flutter/material.dart';
enum AppThemeMode { system, light, dark, green }


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeMode _appThemeMode = AppThemeMode.system; // Default to system theme

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _appThemeMode = AppThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveThemePreference(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void toggleTheme(AppThemeMode mode) {
    setState(() {
      _appThemeMode = mode;
    });
    _saveThemePreference(mode);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData selectedTheme;
    switch (_appThemeMode) {
      case AppThemeMode.green:
        selectedTheme = greenTheme;
        break;
      case AppThemeMode.dark:
        selectedTheme = darkTheme;
        break;
      case AppThemeMode.light:
        selectedTheme = lightTheme;
        break;
      case AppThemeMode.system:
      default:
        selectedTheme = ThemeData.light(); // Fallback to system light theme
        break;
    }

    return MaterialApp(
      theme: selectedTheme,
      darkTheme: darkTheme,
      themeMode: _appThemeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      home: MyAppView(toggleTheme: toggleTheme), // ✅ Pass AppThemeMode function directly
    );
  }
}





// 🎨 Define Light Theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.orange,
    background: Colors.white,
  ),
);

// 🌙 Define Dark Theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  colorScheme: ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.grey,
    background: Colors.black,
  ),
);

// ✅ Define Custom Green Theme
final ThemeData greenTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.green,
  scaffoldBackgroundColor: Colors.green.shade100,
  colorScheme: ColorScheme.light(
    primary: Colors.green,
    secondary: Colors.teal,
    background: Colors.green.shade100,
  ),
);


