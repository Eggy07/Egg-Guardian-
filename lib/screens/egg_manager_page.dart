import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EggDetectionPage extends StatefulWidget {
  const EggDetectionPage({super.key});

  @override
  State<EggDetectionPage> createState() => _EggDetectionPageState();
}

class _EggDetectionPageState extends State<EggDetectionPage> {
  final captureReqCol = FirebaseFirestore.instance.collection(
    'capture_requests',
  );

  final captureDataCol = FirebaseFirestore.instance.collection('captures_data');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Detection Results'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: captureReqCol
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No detections yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final requestDoc = docs[index];
              final requestData = requestDoc.data() as Map<String, dynamic>;

              final requestId = requestDoc.id;
              final batchId = requestData["batch_id"] ?? "Unknown Batch";
              final imagePath = requestData["processed_result_image"] ?? "";
              final timestamp = requestData["timestamp"] != null
                  ? (requestData["timestamp"] as Timestamp).toDate().toString()
                  : "No time";

              // 🔥 We now fetch detection data linked to this request
              return FutureBuilder<QuerySnapshot>(
                future: captureDataCol
                    .where("processed_from_request", isEqualTo: requestId)
                    .limit(1)
                    .get(),
                builder: (context, detectSnap) {
                  if (!detectSnap.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  Map<String, dynamic>? detectData;

                  if (detectSnap.data!.docs.isNotEmpty) {
                    detectData =
                        detectSnap.data!.docs.first.data()
                            as Map<String, dynamic>;
                  }

                  final totalEggs =
                      detectData?["total_eggs"]?.toString() ?? "0";
                  final fertile =
                      detectData?["fertile_eggs"]?.toString() ?? "0";
                  final infertile =
                      (int.tryParse(totalEggs) ?? 0) -
                      (int.tryParse(fertile) ?? 0);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.orange[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Batch: $batchId",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // =======================
                          //      DISPLAY IMAGE
                          // =======================
                          imagePath.isEmpty
                              ? const SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                )
                              : FutureBuilder<String>(
                                  future: FirebaseStorage.instance
                                      .ref(imagePath)
                                      .getDownloadURL(),
                                  builder: (context, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 180,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    if (!snap.hasData || snap.hasError) {
                                      return const SizedBox(
                                        height: 180,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      );
                                    }

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        snap.data!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),

                          const SizedBox(height: 12),

                          Text("📅 Captured: $timestamp"),
                          Text("🥚 Total Eggs: $totalEggs"),
                          Text("🟢 Fertile: $infertile"),
                          Text("🔴 Infertile: $fertile"),

                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await captureReqCol.doc(requestId).delete();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
