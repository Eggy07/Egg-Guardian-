import 'package:flutter/material.dart';

class LiveFeedPage extends StatelessWidget {
  const LiveFeedPage({super.key});

  final List<Map<String, String>> _eggs = const [
    {'id': 'E001', 'status': 'Fertile'},
    {'id': 'E002', 'status': 'Infertile'},
    {'id': 'E003', 'status': 'Fertile'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Live Egg Feed'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eggs.length,
        itemBuilder: (context, index) {
          final egg = _eggs[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.egg),
              title: Text('Egg ID: ${egg['id']}'),
              subtitle: Text('Status: ${egg['status']}'),
            ),
          );
        },
      ),
    );
  }
}
