import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for time formatting

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

  // --- BACKEND LOGIC (UNTOUCHED) ---
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
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
      await _firestore.collection('messages').add({
        'senderId': myId,
        'receiverId': targetUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [myId, targetUserId],
      });
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  // --- UI UPDATES START HERE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=james'), // Placeholder
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUserEmail.split('@')[0], // Display name part of email
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Active 2hrs ago",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          if (isNewChat)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Enter recipient email', border: OutlineInputBorder()),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .where('participants', arrayContains: myId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs
                    .where((doc) => (doc['participants'] as List).contains(otherUserId))
                    .toList();

                docs.sort((a, b) {
                  final aTime = a['timestamp'] as Timestamp?;
                  final bTime = b['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final isMe = doc['senderId'] == myId;
                    final timestamp = doc['timestamp'] as Timestamp?;
                    final timeString = timestamp != null 
                        ? DateFormat('hh:mm a').format(timestamp.toDate()) 
                        : '';

                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          Text(otherUserEmail.split('@')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) 
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: CircleAvatar(radius: 15, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=james')),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1E88E5) : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 20),
                                  ),
                                ),
                                child: Text(
                                  doc['text'] ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(timeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // --- INPUT BAR ---
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type something...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF1E88E5),
                    radius: 24,
                    child: Icon(Icons.send, color: Colors.white, size: 20),
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