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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            ),
          ),
        ),
        title: Text(otherUserEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('participants', arrayContains: myId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs
                    .where(
                      (doc) =>
                          (doc['participants'] as List).contains(otherUserId),
                    )
                    .toList();

                docs.sort((a, b) {
                  final aTime = a['timestamp'];
                  final bTime = b['timestamp'];
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final isMe = doc['senderId'] == myId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF8E2DE2) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          doc['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type something...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
