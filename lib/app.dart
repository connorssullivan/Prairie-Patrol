import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

import 'app_view.dart';

import 'package:flutter/material.dart';
enum AppThemeMode { system, light, dark, green }


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeMode _appThemeMode = AppThemeMode.system; // Default to system theme
  bool _showNotificationButton = false;
  String? _fcmToken;

  @override
  void initState() {
    initializeMessaging();
    super.initState();
    _loadThemePreference();
  }

  Future<void> initializeMessaging() async {
    try {
      print('🚀 Starting messaging initialization...');
      
      // Check if running on iOS Safari
      final isIOS = html.window.navigator.userAgent.contains('iPhone') || 
                    html.window.navigator.userAgent.contains('iPad');
      final isSafari = html.window.navigator.userAgent.contains('Safari') && 
                      !html.window.navigator.userAgent.contains('Chrome');
      
      print('📱 Device info:');
      print('  - iOS: $isIOS');
      print('  - Safari: $isSafari');
      print('  - User Agent: ${html.window.navigator.userAgent}');
      
      // Request permission first
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );
      
      print('📱 Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ Notification permission granted');
        
        // Get FCM token
        String? token = await FirebaseMessaging.instance.getToken(
          vapidKey: 'YOUR_VAPID_KEY', // Add your VAPID key here
        );
        
        if (token != null) {
          print('🔑 FCM Token: $token');
          setState(() {
            _fcmToken = token;
          });
          
          // Save token to your backend or local storage
          await _saveFCMToken(token);
          
          // For iOS Safari, we need to ensure the service worker is registered
          if (isIOS && isSafari) {
            print('📱 iOS Safari detected, registering service worker...');
            try {
              final registration = await html.window.navigator.serviceWorker?.register('/firebase-messaging-sw.js');
              print('✅ Service worker registered: ${registration?.scope}');
            } catch (e) {
              print('❌ Error registering service worker: $e');
            }
          }
        } else {
          print('❌ Failed to get FCM token');
        }
        
        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
          print('🔄 FCM Token refreshed: $token');
          _saveFCMToken(token);
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📩 Received foreground message:');
          print('  - Message ID: ${message.messageId}');
          print('  - Title: ${message.notification?.title}');
          print('  - Body: ${message.notification?.body}');
          print('  - Data: ${message.data}');
          
          showNotifications(message);
        });
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle notification click
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('🔔 Notification clicked:');
          print('  - Message ID: ${message.messageId}');
          print('  - Title: ${message.notification?.title}');
          print('  - Body: ${message.notification?.body}');
        });
        
      } else {
        print('❌ Notification permission denied');
        setState(() {
          _showNotificationButton = true;
        });
      }
    } catch (e) {
      print('❌ Error initializing messaging: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('✅ FCM token saved to local storage');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  Future<void> checkNotificationPermission() async {
    if (kIsWeb) {
      try {
        final permission = await html.window.navigator.permissions?.query({'name': 'notifications'});
        if (permission != null) {
          setState(() {
            _showNotificationButton = permission.state == 'prompt';
          });
        }
      } catch (e) {
        print('Error checking notification permission: $e');
      }
    }
  }

  Future<void> requestNotificationPermission() async {
    if (kIsWeb) {
      try {
        NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );
        
        print('User granted permission: ${settings.authorizationStatus}');
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized || 
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          print('Notification permission granted');
          setState(() {
            _showNotificationButton = false;
          });
          // Reinitialize messaging to get new token
          await initializeMessaging();
        } else {
          print('Notification permission denied');
          // Show a dialog explaining how to enable notifications
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Enable Notifications'),
              content: const Text(
                'To enable notifications on iOS Safari:\n\n'
                '1. Add this app to your home screen\n'
                '2. Open the app from your home screen\n'
                '3. Allow notifications when prompted\n\n'
                'Note: Notifications will only work when the app is added to your home screen.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  void showNotifications(RemoteMessage message) {
    // Handle the notification display logic here
    print('Notification: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    
    // Show a local notification if needed
    if (message.notification != null) {
      // You can show a local notification here if needed
    }
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
      home: Stack(
        children: [
          MyAppView(toggleTheme: toggleTheme),
          if (_showNotificationButton && kIsWeb)
            Positioned(
              top: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: requestNotificationPermission,
                child: const Text('Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Handling background message:');
  print('  - Message ID: ${message.messageId}');
  print('  - Title: ${message.notification?.title}');
  print('  - Body: ${message.notification?.body}');
  print('  - Data: ${message.data}');
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


