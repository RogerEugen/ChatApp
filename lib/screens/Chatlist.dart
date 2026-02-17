import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Login.dart';
import 'Chatscreen.dart';
import 'Contact.dart';
// import '../notification_service.dart';

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

  // --- BACKEND LOGIC (UNTOUCHED) ---
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

  // --- UI UPDATES START HERE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background from image
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black, size: 28),
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.contacts, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Contacts()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar from UI image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
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
                  final otherUser = participants.firstWhere(
                    (id) => id != userId,
                    orElse: () => "",
                  );
                  if (otherUser.isNotEmpty &&
                      !latestChats.containsKey(otherUser)) {
                    latestChats[otherUser] = msg;
                  }
                }

                final otherUserIds = latestChats.keys.toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: otherUserIds.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    final otherId = otherUserIds[index];
                    final msgDoc = latestChats[otherId]!;
                    final latestMessage = msgDoc['text'];
                    final timestamp = msgDoc['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null
                        ? DateFormat('H:mm').format(timestamp.toDate())
                        : "";

                    return FutureBuilder<String>(
                      future: _getUserEmail(otherId),
                      builder: (context, emailSnapshot) {
                        final email = emailSnapshot.data ?? "...";

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://i.pravatar.cc/150?u=$otherId', // Placeholder avatar
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                email.split('@')[0], // Shows name part
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              latestMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () {
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
          ),
        ],
      ),
    );
  }
}
