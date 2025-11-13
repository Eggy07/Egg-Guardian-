import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key, required String userId});

  @override
  State<LedControlPage> createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  final docRef = FirebaseFirestore.instance
      .collection('led_control')
      .doc('status');
  List<bool> leds = List.filled(6, false);
  bool allOn = false;

  Future<void> updateFirestore() async {
    await docRef.set({'leds': leds, 'allOn': allOn}, SetOptions(merge: true));
  }

  void toggleLed(int index) {
    setState(() {
      leds[index] = !leds[index];
      allOn = leds.every((e) => e);
    });
    updateFirestore();
  }

  void toggleAll() {
    setState(() {
      allOn = !allOn;
      leds = List.filled(6, allOn);
    });
    updateFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text(
          'LED Control',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          // Ensure leds is a list of bools, replacing null with false
          leds = List<bool>.generate(6, (i) {
            if (data['leds'] != null && i < (data['leds'] as List).length) {
              return (data['leds'][i] ?? false) as bool;
            }
            return false;
          });

          // Ensure allOn is a bool, default to false
          allOn = (data['allOn'] ?? false) as bool;

          return Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    width: screenHeight * 0.5,
                    height: screenHeight * 0.6,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC400),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'LED Panel',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(
                            allOn ? Icons.power_off : Icons.power,
                            color: Colors.white,
                          ),
                          label: Text(allOn ? 'Turn OFF All' : 'Turn ON All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allOn
                                ? Colors.red[600]
                                : Colors.green[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: toggleAll,
                        ),
                        const SizedBox(height: 25),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                            itemCount: 6,
                            itemBuilder: (context, i) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: leds[i]
                                      ? Colors.green[500]
                                      : Colors.grey[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => toggleLed(i),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 65,
                                      height: 65,
                                      child: Image.asset(
                                        leds[i]
                                            ? 'assets/LON.png'
                                            : 'assets/LO.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
