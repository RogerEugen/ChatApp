<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Chatscreen.dart'; 

class Contacts extends StatefulWidget {
  const Contacts({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get myId => _auth.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text(
          "CONTACT LIST", 
          style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2)
        ),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white))],
        backgroundColor: const Color(0xFF4A90E2), // Matching the blue header in image
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;
          if (users.isEmpty) return const Center(child: Text("No users found"));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final userId = user.id;

              if (userId == myId) return const SizedBox.shrink();

              // Data mapping with fallbacks
              final name = userData['name'] ?? userData['email']?.split('@')[0] ?? 'User';
              final role = userData['role'] ?? 'Profession';
              final location = userData['location'] ?? 'City, ST';
              final imageUrl = userData['profilePic'];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Avatar with border as seen in UI
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 15),
                        
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF4A90E2),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              Text(location, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),

                        // Rounded Icon Buttons
                        _buildActionIcon(Icons.phone),
                        _buildActionIcon(Icons.chat_bubble_outline),
                        _buildActionIcon(Icons.email_outlined),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Icon(icon, size: 16, color: Colors.grey[400]),
    );
  }
=======
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Chatscreen.dart'; // Assuming this is your chat screen

class Contacts extends StatefulWidget {
  const Contacts ({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get myId => _auth.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user.id;
              final email = user['email'];

              // 🚫 Don't show yourself
              if (userId == myId) {
                return const SizedBox.shrink();
              }

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(email),
                onTap: () 
                {
                  // Navigate to ChatScreen with selected contact
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: userId,
                        otherUserEmail: email,
                        isNewChat: false,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
>>>>>>> Kimelejoe
}