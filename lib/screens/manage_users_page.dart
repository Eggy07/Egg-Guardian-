import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User {
  int id;
  String username;
  String email;
  String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'user', // default to 'user'
    );
  }
}

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<User> users = [];
  bool loading = true;
  final String apiBase = 'http://192.168.1.72:3000';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('$apiBase/user'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        users = data.map((e) => User.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => loading = false);
  }

  Future<void> updateRole(User user, String newRole) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBase/user/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': user.username,
          'email': user.email,
          'role': newRole,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => user.role = newRole);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${user.username} updated')));
      } else {
        throw Exception('Failed to update');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: DropdownButton<String>(
                      value: user.role,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) updateRole(user, val);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
