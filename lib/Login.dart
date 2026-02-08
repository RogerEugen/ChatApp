import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/Chatlist.dart';  // Adjust import
import 'Register.dart'; // Adjust import;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // Handle user login
  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Redirect to Chatlist page after login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatList()),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Register screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Register()),
                );
              },
              child: const Text('Don’t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
