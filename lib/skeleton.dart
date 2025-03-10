import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/home%20widgets/drawer_screen.dart';
import 'package:prairiepatrol/screens/home/views/home_screen.dart';
import 'package:prairiepatrol/screens/home/views/stats_screen.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart';
import 'package:prairiepatrol/screens/home/views/test_page.dart';

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

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
    const TestPage(),
  ];

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
                      'Pari Patrol',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  actions: [const SizedBox(width: 48)],
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
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Test',
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


