import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Login.dart';
import 'Chatscreen.dart';
import 'Contact.dart';
import '../notification_service.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get userId => _auth.currentUser!.uid;

  Map<String, String> emailCache = {};
  Set<String> notifiedMessages = {};

  Future<String> _getUserEmail(String uid) async {
    if (emailCache.containsKey(uid)) return emailCache[uid]!;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final email = doc.data()?['email'] ?? uid;
      emailCache[uid] = email;
      return email;
    }
    return uid;
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  void _startNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(
          otherUserId: '',
          otherUserEmail: '',
          isNewChat: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Messages"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Contacts()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .where('participants', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs;

          if (messages.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          messages.sort((a, b) {
            final aTime = a['timestamp'];
            final bTime = b['timestamp'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          final Map<String, QueryDocumentSnapshot> latestChats = {};

          for (var msg in messages) {
            final participants = List<String>.from(msg['participants']);
            final otherUser = participants.firstWhere((id) => id != userId);

            if (!latestChats.containsKey(otherUser)) {
              latestChats[otherUser] = msg;
            }
          }

          final otherUserIds = latestChats.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: otherUserIds.length,
            itemBuilder: (context, index) {
              final otherId = otherUserIds[index];
              final latestMessage = latestChats[otherId]!['text'];

              return FutureBuilder<String>(
                future: _getUserEmail(otherId),
                builder: (context, emailSnapshot) {
                  if (!emailSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final email = emailSnapshot.data!;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF8E2DE2),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        email,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        latestMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: otherId,
                              otherUserEmail: email,
                              isNewChat: false,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8E2DE2),
        onPressed: _startNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }
}
