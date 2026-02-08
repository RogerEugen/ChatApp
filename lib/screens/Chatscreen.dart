import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isNewChat; // if true, user will input email

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.isNewChat = false,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  String get userId => _auth.currentUser?.uid ?? '';
  String otherUserId = '';
  String otherUserEmail = '';

  late bool isNewChat; // ✅ local mutable state

  @override
  void initState() {
    super.initState();
    isNewChat = widget.isNewChat; // initialize local state
    if (!isNewChat) {
      otherUserId = widget.otherUserId;
      otherUserEmail = widget.otherUserName;
    }
  }

  Future<void> _sendMessage() async {
    String receiverId = otherUserId;

    if (isNewChat) {
      final email = _emailController.text.trim();
      final message = _messageController.text.trim();
      if (email.isEmpty || message.isEmpty) return;

      // Find user by email
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      receiverId = query.docs.first.id;
      otherUserId = receiverId;
      otherUserEmail = email;

      // Mark as existing chat now
      setState(() {
        isNewChat = false;
      });
    }

    // Send message
    await _firestore.collection('messages').add({
      'senderId': userId,
      'receiverId': receiverId,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isNewChat
            ? TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter user email',
                ),
              )
            : Text(otherUserEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs
                        .where((doc) =>
                            (doc['senderId'] == userId &&
                                doc['receiverId'] == otherUserId) ||
                            (doc['senderId'] == otherUserId &&
                                doc['receiverId'] == userId))
                        .toList() ??
                    [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == userId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['message'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}