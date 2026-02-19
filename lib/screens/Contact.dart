import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Chatscreen.dart'; // Hakikisha jina la file hili ni sahihi (C kubwa au ndogo)

class Contacts extends StatefulWidget {
  const Contacts({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Anapata ID ya mtumiaji aliyelogin sasa hivi
  String get myId => _auth.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text(
          "CONTACT LIST",
          style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.add, color: Colors.white)
          )
        ],
        backgroundColor: const Color(0xFF4A90E2), // Rangi ya Bluu
        elevation: 0,
      ),
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
              final userData = user.data() as Map<String, dynamic>;
              final userId = user.id;

              // Usijionyeshe mwenyewe kwenye list
              if (userId == myId) return const SizedBox.shrink();

              // Taarifa za mtumiaji
              final email = userData['email'] ?? 'No Email';
              final name = userData['name'] ?? email.split('@')[0];
              final role = userData['role'] ?? 'Profession';
              final location = userData['location'] ?? 'City, ST';
              final imageUrl = userData['profilePic'];

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      // Hapa ndipo unapoenda kwenye Chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Chatscreen(
                            receiverId: userId,
                            receiverEmail: email,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          // Picha ya Mtumiaji
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                            child: imageUrl == null 
                                ? const Icon(Icons.person, color: Colors.white) 
                                : null,
                          ),
                          const SizedBox(width: 15),
                          
                          // Maelezo (Jina, Role, Location)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Color(0xFF4A90E2),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Text(location, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                          ),

                          // Icons za pembeni
                          _buildActionIcon(Icons.phone),
                          _buildActionIcon(Icons.chat_bubble_outline),
                          _buildActionIcon(Icons.email_outlined),
                        ],
                      ),
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

  // Widget ya kutengeneza vijidude vya icons za pembeni
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
}