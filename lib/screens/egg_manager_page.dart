import 'package:flutter/material.dart';

class EggManagerPage extends StatelessWidget {
  const EggManagerPage({super.key});

  final List<Map<String, dynamic>> _batches = const [
    {'batch': 'Batch 1', 'fertile': 12, 'infertile': 3},
    {'batch': 'Batch 2', 'fertile': 10, 'infertile': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Egg Manager'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          final batch = _batches[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(batch['batch']),
              subtitle: Text(
                'Fertile: ${batch['fertile']}, Infertile: ${batch['infertile']}',
              ),
              trailing: const Icon(Icons.history),
            ),
          );
        },
      ),
    );
  }
}
