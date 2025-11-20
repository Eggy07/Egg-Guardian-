import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggguardian_finalv/screens/egg_details_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class EggManagerPage extends StatelessWidget {
  const EggManagerPage({super.key});

  // Convert image path to Firebase Storage download URL
  Future<String> getDownloadUrl(String path) async {
    if (path.isEmpty) return '';
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Failed to get download URL for $path: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Egg Manager'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('egg_results')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No egg captures yet."));
          }

          final docs = snapshot.data!.docs;

          // Group by batch (date)
          Map<String, List<QueryDocumentSnapshot>> batches = {};
          for (var doc in docs) {
            String date = (doc['date'] ?? "").isNotEmpty
                ? doc['date']
                : "Unknown Batch";
            batches.putIfAbsent(date, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: batches.entries.map((batch) {
              String batchName = batch.key;
              List<QueryDocumentSnapshot> eggs = batch.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ExpansionTile(
                  title: Text(
                    "Batch: $batchName",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text("${eggs.length} eggs captured"),
                  children: eggs.map((eggDoc) {
                    final data = eggDoc.data() as Map<String, dynamic>;

                    final status = (data['status'] ?? "").trim().isNotEmpty
                        ? data['status'].trim()
                        : "unknown";
                    final confidence = (data['confidence'] ?? "").isNotEmpty
                        ? data['confidence']
                        : "N/A";
                    final eggId = (data['egg_id'] ?? "").isNotEmpty
                        ? data['egg_id']
                        : "N/A";
                    final imagePath = (data['image_url'] ?? "").isNotEmpty
                        ? data['image_url']
                        : "";

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath.isNotEmpty
                            ? FutureBuilder<String>(
                                future: getDownloadUrl(imagePath),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  final imageUrl = snapshot.data;
                                  return (imageUrl != null &&
                                          imageUrl.isNotEmpty)
                                      ? Image.network(
                                          imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.red,
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.red,
                                          ),
                                        );
                                },
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                      title: Text(
                        "Status: $status",
                        style: TextStyle(
                          color: status.toLowerCase() == "fertile"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("Confidence: $confidence\nEgg ID: $eggId"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EggDetailsPage(data: data),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
