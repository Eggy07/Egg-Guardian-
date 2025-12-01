import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveFeedPage extends StatefulWidget {
  const LiveFeedPage({super.key});

  @override
  State<LiveFeedPage> createState() => _LiveFeedPageState();
}

class _LiveFeedPageState extends State<LiveFeedPage> {
  final String imageUrl =
      "https://firebasestorage.googleapis.com/v0/b/eggguardian-19ee3.firebasestorage.app/o/live_feed%2Fcurrent.jpg?alt=media";

  Uint8List? _imageBytes;
  Uint8List? _prevBytes;
  bool _cameraOffline = false;
  Timer? _timer;
  DateTime lastFrameTime = DateTime.now();

  // ---------------------------
  // TEMP & HUMIDITY FROM DHT11
  // ---------------------------
  double? temperature;
  double? humidity;

  // ---------------------------
  // BATCH DROPDOWN CONTROLLER
  // ---------------------------
  String? selectedBatch;
  List<String> batchList = ["batch1", "batch2", "batch3"];

  @override
  void initState() {
    super.initState();

    _loadImage();
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _loadImage(),
    );

    // CAMERA OFFLINE CHECK
    Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = DateTime.now().difference(lastFrameTime).inSeconds;
      if (diff >= 10 && !_cameraOffline) {
        setState(() => _cameraOffline = true);
      }
    });

    // ---------------------------
    // FIRESTORE LISTENER FOR DHT11
    // ---------------------------
    FirebaseFirestore.instance
        .collection("captures_data")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            setState(() {
              temperature = (data["temperature"]?.toDouble() ?? 0.0);
              humidity = (data["humidity"]?.toDouble() ?? 0.0);
            });
          }
        });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final response = await http.get(
        Uri.parse("$imageUrl&v=${DateTime.now().millisecondsSinceEpoch}"),
      );

      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;
        bool sameFrame = false;

        if (_prevBytes != null &&
            _prevBytes!.length == bytes.length &&
            listEquals(_prevBytes, bytes)) {
          sameFrame = true;
        }

        if (!sameFrame) {
          lastFrameTime = DateTime.now();
          setState(() {
            _cameraOffline = false;
            _imageBytes = bytes;
            _prevBytes = bytes;
          });
        }
      }
    } catch (e) {}
  }

  // ---------------------------
  // CAPTURE WITH SELECTED BATCH
  // ---------------------------
  Future<void> _captureEgg() async {
    if (selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a batch first")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("capture_requests").add({
        "batch_id": selectedBatch,
        "timestamp": FieldValue.serverTimestamp(),
        "processed": false,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Capture sent to $selectedBatch")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Egg Feed"),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---------------------------
          // TEMPERATURE + HUMIDITY UI
          // ---------------------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    temperature == null
                        ? "Temp: --°C"
                        : "Temp: ${temperature!.toStringAsFixed(1)}°C",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    humidity == null
                        ? "Humidity: --%"
                        : "Humidity: ${humidity!.toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------
          // CAMERA STREAM
          // ---------------------------
          Expanded(
            child: Center(
              child: _cameraOffline
                  ? const Text(
                      "📷 CAMERA OFFLINE",
                      style: TextStyle(fontSize: 22, color: Colors.red),
                    )
                  : _imageBytes == null
                  ? const CircularProgressIndicator()
                  : Image.memory(_imageBytes!, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 10),

          // ---------------------------
          // BATCH DROPDOWN UI
          // ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Batch",
                border: OutlineInputBorder(),
              ),
              value: selectedBatch,
              items: batchList.map((batch) {
                return DropdownMenuItem(value: batch, child: Text(batch));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedBatch = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _captureEgg,
              icon: const Icon(Icons.camera),
              label: const Text("Capture Egg"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC400),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
