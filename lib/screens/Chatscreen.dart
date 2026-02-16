import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isNewChat;

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

  late bool isNewChat;

  @override
  void initState() {
    super.initState();
    isNewChat = widget.isNewChat;
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

      setState(() {
        isNewChat = false;
      });
    }

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
      backgroundColor: const Color(0xFFFDECEF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDECEF),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: isNewChat
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Enter user email',
                    border: InputBorder.none,
                  ),
                ),
              )
            : Column(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.pinkAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    otherUserEmail,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          /// Messages Area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs
                    .where((doc) =>
                        (doc['senderId'] == userId &&
                            doc['receiverId'] == otherUserId) ||
                        (doc['senderId'] == otherUserId &&
                            doc['receiverId'] == userId))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == userId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.pinkAccent
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                            color:
                                isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// Message Input Area
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: const Color(0xFFFDECEF),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.pinkAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
