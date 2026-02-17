import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Login.dart';
import 'Chatscreen.dart';
import 'Contact.dart';  // Import the Contacts screen
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
  Set<String> notifiedMessages = {}; // 🔥 Track which messages have notified

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
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          // IconButton for navigating to Contacts screen
          IconButton(
            icon: const Icon(Icons.contacts),  // Contact icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Contacts()),  // Navigate to Contacts
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

          if (messages.isEmpty) return const Center(child: Text('No chats yet'));

          // Sort messages by timestamp
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

            // Track latest message per user
            if (!latestChats.containsKey(otherUser)) {
              latestChats[otherUser] = msg;
            }
          }

          final otherUserIds = latestChats.keys.toList();

          return ListView.builder(
            itemCount: otherUserIds.length,
            itemBuilder: (context, index) {
              final otherId = otherUserIds[index];
              final latestMessage = latestChats[otherId]!['text'];

              return FutureBuilder<String>(
                future: _getUserEmail(otherId),
                builder: (context, emailSnapshot) {
                  if (!emailSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final email = emailSnapshot.data!;

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(email),
                    subtitle: Text(latestMessage),
                    onTap: () async {
                      // Mark messages as read when opening chat
                      final chatMessages = await _firestore
                          .collection('messages')
                          .where('participants', arrayContains: userId)
                          .get();

                      for (var doc in chatMessages.docs) {
                        if (doc['senderId'] == otherId &&
                            doc['receiverId'] == userId &&
                            doc['isRead'] == false) {
                          await doc.reference.update({'isRead': true});
                        }
                      }

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
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }
}