import 'package:flutter/material.dart';

class EggDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const EggDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: Text("Egg: ${data['egg_id']}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                data['image_url'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Status: ${data['status']}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: data['status'] == "fertile" ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Confidence: ${data['confidence']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Captured On: ${data['date']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Egg ID: ${data['egg_id']}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
