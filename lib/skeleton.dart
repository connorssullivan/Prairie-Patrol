import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/home%20widgets/drawer_screen.dart';
import 'package:prairiepatrol/screens/home/views/home_screen.dart';
import 'package:prairiepatrol/screens/home/views/stats_screen.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart';
import 'package:prairiepatrol/screens/home/views/test_page.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedPage = 0;
  bool _isDrawerOpen = false; // Tracks if drawer is open
  double xOffSet = 0;
  double yOffset = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
    const TestPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = index;
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DrawerScreen(), // Your custom drawer screen in the background
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(xOffSet, yOffset, 0)
            ..scale(_isDrawerOpen ? 0.85 : 1.00)
            ..rotateZ(_isDrawerOpen ? -50 : 0), // Slide effect
          color: Colors.white,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _toggleDrawer, // Toggle the drawer on button press
              ),
              title: const Center(
                child: Text(
                  'Pari Patrol',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              actions: [
                SizedBox(width: 48), // Keeps the title centered
              ],
            ),
            body: _pages[_selectedPage], // Display the selected page
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Test',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
