import 'package:eggguardian_finalv/screens/led_control.dart';
import 'package:flutter/material.dart';
import 'package:eggguardian_finalv/screens/account_page.dart';
import 'package:eggguardian_finalv/screens/login_page.dart';
import '../theme_controller.dart';
import 'message_concern_page.dart';
import '../screens/notification_page.dart';

class SettingsPage extends StatelessWidget {
  final int userId; // logged-in user ID

  const SettingsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Navigation
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountPage(userId: userId)),
              );
            },
          ),
          // LED Control
          ListTile(
            leading: const Icon(Icons.lightbulb),
            title: const Text('LED Control'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LedControlPage(userId: userId),
                ),
              );
            },
          ),
          const Divider(),

          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationPage(userId: userId),
                ),
              );
            },
          ),

          // Message Concern / Ticketing
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Message Concern'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageConcernPage(userId: userId),
                ),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.themeMode,
              builder: (context, mode, _) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (val) => ThemeController.toggleTheme(),
                );
              },
            ),
          ),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
