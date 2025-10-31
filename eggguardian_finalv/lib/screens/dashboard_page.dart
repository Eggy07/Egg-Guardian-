import 'package:eggguardian_finalv/screens/account_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  final int userId;

  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _hatchingDay;
  bool _reminderEnabled = true;
  final List<Map<String, dynamic>> _notifications = [];
  final String apiBase = 'http://192.168.1.55:3000';

  @override
  void initState() {
    super.initState();
    _loadHatchingData();
    _fetchAdminReplies();
  }

  Future<void> _loadHatchingData() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('hatchingDay');
    final reminderEnabled = prefs.getBool('reminderEnabled') ?? true;

    setState(() {
      _hatchingDay = dateString != null ? DateTime.parse(dateString) : null;
      _reminderEnabled = reminderEnabled;
    });

    _updateHatchingNotification();
  }

  void _updateHatchingNotification() {
    if (!_reminderEnabled || _hatchingDay == null) return;

    final now = DateTime.now();
    final difference = _hatchingDay!.difference(now).inDays;

    if (difference >= 0 && difference <= 7) {
      _notifications.add({
        'type': 'hatching',
        'message': difference == 0
            ? '🥚 Your egg is hatching today!'
            : '🐣 Your egg will hatch in $difference day(s)',
      });
      setState(() {});
    }
  }

  Future<void> _fetchAdminReplies() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/messages/${widget.userId}'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final repliedMessages = data.where(
          (m) =>
              m['admin_response'] != null &&
              m['admin_response'].toString().isNotEmpty,
        );

        for (final m in repliedMessages) {
          _notifications.add({
            'type': 'admin_reply',
            'message': '📩 Admin replied: "${m['subject']}"',
            'data': m,
          });
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching admin replies: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['type'] == 'admin_reply') {
      final msg = notification['data'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin reply: "${msg['admin_response']}"')),
      );
    } else if (notification['type'] == 'hatching') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notification['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC400),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/chick_icon.png', height: 35),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountPage(userId: widget.userId),
                      ),
                    );
                  },
                  child: const Icon(Icons.person_2, size: 28),
                ),
              ],
            ),
          ),

          // Notification Banner (Vertical)
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: _notifications.map((notif) {
                  return GestureDetector(
                    onTap: () => _handleNotificationTap(notif),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              notif['message'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 10),

          // Welcome Card
          Expanded(
            child: Center(
              child: Container(
                width: screenHeight * 0.5,
                height: screenHeight * 0.6,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC400),
                  borderRadius: BorderRadius.circular(40),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.1),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Image.asset(
                        'assets/chick_welcome.png',
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome,\nUser!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4.0,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
