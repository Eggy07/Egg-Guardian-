import 'package:eggguardian_finalv/screens/manage_users_page.dart';
import 'package:flutter/material.dart';
import 'message_concern_admin_page.dart';
import 'login_page.dart'; // Make sure this path is correct

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFFF8E1,
      ), // Light dashboard-like background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildCard(
              icon: Icons.analytics,
              label: 'View Egg Logs',
              onTap: () {
                // TODO: Navigate to logs page
              },
            ),
            const SizedBox(height: 20),

            _buildCard(
              icon: Icons.message,
              label: 'Message Concerns',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessageConcernsAdminPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            _buildCard(
              icon: Icons.lightbulb,
              label: 'Control Lights (All)',
              onTap: () {
                // TODO: Navigate to lights control page
              },
            ),
            const SizedBox(height: 20),

            _buildCard(
              icon: Icons.people,
              label: 'Manage Users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersPage()),
                );
              },
            ),

            const SizedBox(height: 20),

            // Logout Card
            _buildCard(
              icon: Icons.logout,
              label: 'Logout',
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
                          // Navigate to LoginPage and remove previous routes
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
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
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFECB3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(2, 4),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.black87),
            const SizedBox(width: 20),
            Text(label, style: const TextStyle(fontSize: 18)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
