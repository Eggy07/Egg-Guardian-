import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessageConcernsAdminPage extends StatefulWidget {
  const MessageConcernsAdminPage({super.key});

  @override
  State<MessageConcernsAdminPage> createState() =>
      _MessageConcernsAdminPageState();
}

class _MessageConcernsAdminPageState extends State<MessageConcernsAdminPage> {
  List messages = [];
  final TextEditingController _responseController = TextEditingController();
  final String baseUrl = "http://192.168.1.72:3000";

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/messages'));
      if (res.statusCode == 200) {
        setState(() {
          messages = json.decode(res.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> sendResponse(int messageId) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/messages/respond/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'adminResponse': _responseController.text}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent successfully!')),
        );
        _responseController.clear();
        fetchMessages(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error sending response: $e');
    }
  }

  void _respond(int messageId) {
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
            onPressed: () {
              Navigator.pop(context);
              _responseController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await sendResponse(messageId); // wait for the response to finish
              Navigator.pop(context); // close dialog after success
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Concerns'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: messages.isEmpty
          ? const Center(child: Text('No messages yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: const Color(0xFFFFECB3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _respond(msg['message_id']),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['subject'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(msg['message']),
                          if (msg['admin_response'] != null &&
                              msg['admin_response'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Admin: ${msg['admin_response']}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(msg['username'] ?? 'User'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
