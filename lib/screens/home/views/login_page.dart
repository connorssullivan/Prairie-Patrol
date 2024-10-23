import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zoo Worker Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/images/zoo_logo.png', height: 100), // Add a zoo logo
            SizedBox(height: 20),
            Text(
              'Welcome to Prairie Patrol',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your login logic here
                if (_usernameController.text == 'admin' && _passwordController.text == 'admin') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login successful')));
                  widget.onLogin(); // Call the login callback
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Corrected button color parameter
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
