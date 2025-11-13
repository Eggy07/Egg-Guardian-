import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageConcernPage extends StatefulWidget {
  final String userId;

  const MessageConcernPage({super.key, required this.userId});

  @override
  State<MessageConcernPage> createState() => _MessageConcernPageState();
}

class _MessageConcernPageState extends State<MessageConcernPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final CollectionReference concernMessages = FirebaseFirestore.instance
      .collection('concern_messages');

  List<Map<String, dynamic>> _localMessages = [];

  /// Send message locally and to Firestore
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final newMessage = {
      'user_id': widget.userId,
      'subject': _subjectController.text.trim(),
      'message': _messageController.text.trim(),
      'admin_response': null,
      'created_at': FieldValue.serverTimestamp(),
      'local_created_at': now,
    };

    // Show immediately
    setState(() {
      _localMessages.insert(0, newMessage);
    });

    _subjectController.clear();
    _messageController.clear();

    try {
      await concernMessages.add(newMessage);
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sending message')));
    }
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    final subject = msg['subject'] ?? 'No Subject';
    final message = msg['message'] ?? '';
    final adminResponse = msg['admin_response'] ?? '';
    final dynamic createdAtField =
        msg['created_at'] ?? msg['local_created_at'] ?? DateTime.now();

    String formattedTime = '';
    if (createdAtField is Timestamp) {
      formattedTime = createdAtField.toDate().toLocal().toString();
    } else if (createdAtField is DateTime) {
      formattedTime = createdAtField.toLocal().toString();
    } else {
      formattedTime = createdAtField.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFFFFECB3),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message),
            if (adminResponse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Admin: $adminResponse',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Concern'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: concernMessages
                  .orderBy('created_at', descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final serverMessages =
                    snapshot.data?.docs
                        .map((e) => e.data() as Map<String, dynamic>)
                        .where((msg) => msg['user_id'] == widget.userId)
                        .toList() ??
                    [];

                // Merge local + server messages, prioritize server for admin_response
                final mergedMessages = [
                  ...serverMessages,
                  ..._localMessages.where(
                    (lMsg) => !serverMessages.any(
                      (sMsg) =>
                          sMsg['message'] == lMsg['message'] &&
                          sMsg['subject'] == lMsg['subject'],
                    ),
                  ),
                ];

                if (mergedMessages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mergedMessages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageCard(mergedMessages[index]),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a subject' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a message' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC400),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
