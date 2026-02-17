import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserEmail;
  final bool isNewChat;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserEmail,
    this.isNewChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  String get myId => _auth.currentUser!.uid;

  late String otherUserId;
  late String otherUserEmail;
  late bool isNewChat;

  @override
  void initState() {
    super.initState();
    otherUserId = widget.otherUserId;
    otherUserEmail = widget.otherUserEmail;
    isNewChat = widget.isNewChat;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    String targetUserId = otherUserId;
    String targetEmail = otherUserEmail;

    try {
      if (isNewChat) {
        final email = _emailController.text.trim();
        if (email.isEmpty) return;

        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
          return;
        }

        targetUserId = userQuery.docs.first.id;
        targetEmail = email;

        await _firestore.collection('messages').add({
          'senderId': myId,
          'receiverId': targetUserId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'participants': [myId, targetUserId],
        });

        _messageController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: targetUserId,
              otherUserEmail: targetEmail,
              isNewChat: false,
            ),
          ),
        );

        return;
      }

      // Normal chat
      await _firestore.collection('messages').add({
        'senderId': myId,
        'receiverId': targetUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [myId, targetUserId],
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isNewChat
            ? TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter user email to start chat',
                ),
                keyboardType: TextInputType.emailAddress,
              )
            : Text(otherUserEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('participants', arrayContains: myId)
                  .snapshots(), // 🔥 removed orderBy
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs
                    .where((doc) =>
                        (doc['participants'] as List).contains(otherUserId))
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                // 🔥 Safe sort (newest last)
                docs.sort((a, b) {
                  final aTime = a['timestamp'];
                  final bTime = b['timestamp'];

                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                return ListView.builder(
                  reverse: true, // 🔥 chat style
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[docs.length - 1 - index];
                    final isMe = doc['senderId'] == myId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doc['text'] ?? '',
                          style: TextStyle(
                            color:
                                isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12),
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