import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageConcernsAdminPage extends StatefulWidget {
  const MessageConcernsAdminPage({super.key});

  @override
  State<MessageConcernsAdminPage> createState() =>
      _MessageConcernsAdminPageState();
}

class _MessageConcernsAdminPageState extends State<MessageConcernsAdminPage> {
  final TextEditingController _responseController = TextEditingController();

  final CollectionReference messagesCollection = FirebaseFirestore.instance
      .collection('concern_messages');

  /// Open dialog to type admin response
  void _respond(String docId) {
    _responseController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Message'),
        content: TextField(
          controller: _responseController,
          decoration: const InputDecoration(hintText: 'Enter your response'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await sendResponse(docId);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /// Send admin response to Firestore
  Future<void> sendResponse(String docId) async {
    try {
      await messagesCollection.doc(docId).update({
        'admin_response': _responseController.text,
        'response_time': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response sent successfully!')),
      );
      _responseController.clear();
    } catch (e) {
      debugPrint('Error sending response: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sending response')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Messages'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesCollection
            .orderBy('created_at', descending: true)
            .snapshots(includeMetadataChanges: true), // ← fix here
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final msg = docs[index];
              final String docId = msg.id;
              final data = msg.data() as Map<String, dynamic>;
              final String subject = data['subject'] ?? 'No subject';
              final String message = data['message'] ?? '';
              final String adminResponse = data['admin_response'] ?? '';
              final String user = data['user_id'] ?? 'User';

              // Handle timestamps safely
              final Timestamp? createdAtTs = data['created_at'] as Timestamp?;
              final Timestamp? responseTs = data['response_time'] as Timestamp?;
              final String createdAt = createdAtTs != null
                  ? createdAtTs.toDate().toLocal().toString()
                  : 'Just now'; // fallback for new messages
              final String respondedAt = responseTs != null
                  ? responseTs.toDate().toLocal().toString()
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: const Color(0xFFFFECB3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _respond(docId),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(message),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            'Sent: $createdAt',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        if (adminResponse.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin: $adminResponse',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (respondedAt.isNotEmpty)
                                  Text(
                                    'Responded: $respondedAt',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(user),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
