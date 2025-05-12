import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/home%20widgets/drawer_screen.dart';
import 'package:prairiepatrol/screens/home/views/home_screen.dart';
import 'package:prairiepatrol/screens/home/views/stats_screen.dart';
import '../../../services/rt_dogs_service.dart';
import 'app.dart';

class Skeleton extends StatefulWidget {
  final Function(AppThemeMode) toggleTheme; // ✅ Accept `AppThemeMode`

  const Skeleton({super.key, required this.toggleTheme});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedPage = 0;
  bool _isDrawerOpen = false;
  double xOffSet = 0;
  double yOffset = 0;
  int? _batteryLife;

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToBatteryLife(); // Subscribe to battery life updates
  }

  void _subscribeToBatteryLife() {
    // Listen for changes in battery life
    RTDogsService().dbRef.child('Config/BatteryLife').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          _batteryLife = event.snapshot.value as int?;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = index;
      if (_isDrawerOpen) _toggleDrawer(); // ✅ Close drawer when switching tabs
    });
  }

  void _toggleDrawer() {
    setState(() {
      if (_isDrawerOpen) {
        xOffSet = 0;
        yOffset = 0;
      } else {
        xOffSet = 290;
        yOffset = 80;
      }
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  // Helper function to determine battery icon color
  Color _getBatteryIconColor(int batteryPercentage) {
    if (batteryPercentage > 79) {
      return Colors.green; // Full battery
    } else if (batteryPercentage > 29) {
      return Colors.yellow; // Medium battery
    } else {
      return Colors.red; // Low battery
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Pass `AppThemeMode` to `DrawerScreen`
        DrawerScreen(toggleTheme: widget.toggleTheme, closeDrawer: _toggleDrawer),

        // ✅ Prevent main screen interactions when drawer is open
        IgnorePointer(
          ignoring: _isDrawerOpen,
          child: GestureDetector(
            onTap: () {
              if (_isDrawerOpen) _toggleDrawer();
            },
            behavior: HitTestBehavior.translucent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(xOffSet, yOffset, 0)
                ..scale(_isDrawerOpen ? 0.85 : 1.00)
                ..rotateZ(_isDrawerOpen ? -50 : 0),
              color: Colors.white,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _toggleDrawer,
                  ),
                  title: const Center(
                    child: Text(
                      'Prairie Patrol',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  actions: [
                    // Battery life icon in the upper right
                    if (_batteryLife != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.battery_full,
                              color: _getBatteryIconColor(_batteryLife!), // Dynamic color based on battery percentage
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$_batteryLife%',
                              style: TextStyle(
                                color: _getBatteryIconColor(_batteryLife!), // Match text color to icon color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 48),
                  ],
                ),
                body: _pages[_selectedPage],
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedPage,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart),
                      label: 'Stats',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
