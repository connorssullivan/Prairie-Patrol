
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prairiepatrol/screens/home/views/settings_screen.dart';
import '../../../services/auth.dart'; // Import your login page

class DrawerScreen extends StatefulWidget {
  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  final Auth _auth = Auth(); // Create an instance of Auth

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey,
      child: Padding(
        padding: const EdgeInsets.only(top: 50, left: 40, bottom: 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/images/fox.png'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30), // Space between profile and menu

            // Menu Items Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                NewRow(
                  text: 'Settings',
                  icon: Icons.settings,
                  onTap: () {
                    // Navigate to settings if needed
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                  },
                ),
                const SizedBox(height: 20),
                NewRow(
                  icon: Icons.logout,
                  text: 'Logout',
                  onTap: () {
                    _auth.signOutAndNavigateToLogin(context); // Sign out and navigate to login
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const NewRow({
    Key? key,
    required this.icon,
    required this.text,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}




