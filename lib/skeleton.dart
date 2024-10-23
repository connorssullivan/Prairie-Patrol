import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/home_screen.dart';
import 'package:prairiepatrol/screens/home/views/stats_screen.dart';
import 'package:prairiepatrol/screens/home/views/login_page.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedPage = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pari Patrol',
          style: TextStyle(color: Colors.green),
        ),
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
            label: 'Home',
          ),
          ],
      ),
    );
  }
}