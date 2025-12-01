import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EggBatchPage extends StatefulWidget {
  const EggBatchPage({super.key});

  @override
  State<EggBatchPage> createState() => _EggBatchPageState();
}

class _EggBatchPageState extends State<EggBatchPage> {
  final CollectionReference batchCollection = FirebaseFirestore.instance
      .collection('egg_batches');

  final ImagePicker _picker = ImagePicker();

  /// Add image for a specific day
  Future<void> addEggImage(String batchId, int day) async {
    if (day < 1 || day > 21) return; // safeguard
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File imgFile = File(image.path);

    // For simplicity, we store the image path in Firestore (replace with upload URL if using Firebase Storage)
    final String imagePath = imgFile.path;

    // Ask status
    String? status = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController _statusController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Egg Status'),
          content: TextField(
            controller: _statusController,
            decoration: const InputDecoration(hintText: 'Fertile / Infertile'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _statusController.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (status == null) return;

    final String dayField = 'day_$day';

    try {
      await batchCollection.doc(batchId).set({
        dayField: FieldValue.arrayUnion([
          {
            'image_path': imagePath,
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
          },
        ]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added image for Day $day!')));
    } catch (e) {
      debugPrint('Error adding egg image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Batch Tracker'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: batchCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No batches yet'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final batch = docs[index];
              final String batchId = batch.id;
              final data = batch.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                color: const Color(0xFFFFECB3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch: $batchId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Display images per day
                      for (int day = 1; day <= 21; day++)
                        if (data['day_$day'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day $day'),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (data['day_$day'] as List).length,
                                  itemBuilder: (context, i) {
                                    final img = data['day_$day'][i];
                                    return Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Column(
                                        children: [
                                          Image.file(
                                            File(img['image_path']),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(
                                            img['status'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                      ElevatedButton(
                        onPressed: () => addEggImage(
                          batchId,
                          1,
                        ), // Example: add image for day 1
                        child: const Text('Add Egg Image'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
