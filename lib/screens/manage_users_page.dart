import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateRole(String uid, String newRole) async {
    try {
      await _firestore.collection('user').doc(uid).update({'role': newRole});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User role updated to $newRole')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating role: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Firestore snapshots update automatically, so just wait a moment
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final uid = doc.id;
                final email = doc['email'] ?? 'No Email';
                final fullName = doc['full_name'] ?? 'No Name';
                final roleRaw = (doc['role'] ?? 'user')
                    .toString()
                    .toLowerCase();
                final role = roleRaw == 'admin' ? 'admin' : 'user';

                return ListTile(
                  title: Text(fullName),
                  subtitle: Text(email),
                  trailing: DropdownButton<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) updateRole(uid, val);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
