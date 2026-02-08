import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Login.dart';
import 'Chatscreen.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  // Open ChatScreen for a new chat
  void _startNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: '',
          otherUserName: '',
          isNewChat: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .where('senderId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final messages = snapshot.data?.docs ?? [];

          // Extract unique receiver IDs
          final uniqueReceiverIds = messages
              .map((message) => message['receiverId'])
              .toSet()
              .toList();

          if (uniqueReceiverIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No chats yet!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startNewChat,
                    child: const Text('Start a new chat'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: uniqueReceiverIds.length,
            itemBuilder: (context, index) {
              final receiverId = uniqueReceiverIds[index];
              return ListTile(
                title: Text('Chat with $receiverId'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: receiverId,
                        otherUserName: receiverId,
                      ),
                    ),
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