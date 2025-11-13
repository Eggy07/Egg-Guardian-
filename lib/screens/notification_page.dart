import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_concern_page.dart'; // Import your message page

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  final String apiBase = 'http://192.168.1.72:3000';
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadHatchingDay();
    _checkAdminReplies();
  }

  // Load hatching day from SharedPreferences
  Future<void> _loadHatchingDay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('hatchingDay');

    if (dateString != null) {
      final hatchingDay = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = hatchingDay.difference(now).inDays + 1;

      if (difference == 0) {
        notifications.add({
          'type': 'hatching',
          'message': '🥚 Your egg is hatching today!',
          'data': null,
        });
      } else if (difference > 0 && difference <= 7) {
        notifications.add({
          'type': 'hatching',
          'message': '🐣 Your egg will hatch in $difference day(s)',
          'data': null,
        });
      }
      setState(() {});
    }
  }

  // Check admin replies for the logged-in user
  Future<void> _checkAdminReplies() async {
    if (user == null) return; // No logged-in user
    try {
      final res = await http.get(Uri.parse('$apiBase/messages/${user!.uid}'));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        final repliedMessages = data.where(
          (msg) =>
              msg['admin_response'] != null &&
              msg['admin_response'].toString().isNotEmpty,
        );

        for (var msg in repliedMessages) {
          notifications.add({
            'type': 'admin_reply',
            'message': '📩 Admin replied to: "${msg['subject']}"',
            'data': msg,
          });
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching admin replies: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['type'] == 'admin_reply' && user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessageConcernPage(userId: user!.uid),
        ),
      );
    } else if (notification['type'] == 'hatching') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egg details not implemented yet!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No new notifications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.orange[200],
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(notif['message']),
                    onTap: () => _handleNotificationTap(notif),
                  ),
                );
              },
            ),
    );
  }
}
