  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
  import 'screens/Chatlist.dart'; // Adjust import
  import 'Login.dart';

  class Register extends StatefulWidget {
    const Register({super.key});

    @override
    _RegisterState createState() => _RegisterState();
  }

  class _RegisterState extends State<Register> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance; // ✅ Add this

    // Handle user registration
    Future<void> _register() async {
      try {
        // Create user with Firebase Authentication
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user info to Firestore (e.g., email)
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(), // Store the email
          'uid': userCredential.user!.uid,        // Store the user ID
        });

        // Redirect to the ChatList page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatList()),
        );
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
      }
    }

    @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [

            // 🔵 Top Gradient Design
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 118, 38, 189), Color.fromARGB(255, 106, 37, 244)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              padding: const EdgeInsets.only(left: 24, top: 60),
              alignment: Alignment.topLeft,
              child: const Text(
                "Register",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 📧 Email details 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 136, 42, 153)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔐 Password Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🔵 Register if you havent an account
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8E2DE2),
                          Color.fromARGB(255, 91, 10, 253)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🔵 Bottom Login Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?? "),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    "Login >",
                    style: TextStyle(
                      color: Color.fromARGB(255, 178, 89, 194),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  }
