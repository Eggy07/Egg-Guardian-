import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/concern_message.dart';

class MessageConcernPage extends StatefulWidget {
  final int userId;

  const MessageConcernPage({super.key, required this.userId});

  @override
  State<MessageConcernPage> createState() => _MessageConcernPageState();
}

class _MessageConcernPageState extends State<MessageConcernPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<ConcernMessage> userMessages = [];
  final String apiBase = 'http://192.168.1.55:3000'; // your backend IP

  // Fetch messages for this user
  Future<void> fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/messages/${widget.userId}'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          userMessages = data.map((m) {
            return ConcernMessage(
              userId: m['user_id'],
              userName: m['username'] ?? 'User ${m['user_id']}',
              subject: m['subject'],
              message: m['message'],
              adminResponse: m['admin_response'],
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  // Send message to backend
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final res = await http.post(
        Uri.parse('$apiBase/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
        _subjectController.clear();
        _messageController.clear();
        fetchMessages(); // refresh
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server connection error')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
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
          // Messages list
          Expanded(
            child: userMessages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: userMessages.length,
                    itemBuilder: (context, index) {
                      final msg = userMessages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: const Color(0xFFFFECB3),
                        child: ListTile(
                          title: Text(
                            msg.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg.message),
                              if (msg.adminResponse != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Admin: ${msg.adminResponse}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // Send form
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
