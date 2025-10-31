import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LedControlPage extends StatefulWidget {
  final int userId;

  const LedControlPage({super.key, required this.userId});

  @override
  State<LedControlPage> createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  List<bool> leds = List.filled(6, false);
  bool allOn = false;

  // --- Raspberry Pi IP ---
  final String baseUrl = 'http://192.168.1.101:5000/led';
  final String baseAllUrl = 'http://192.168.1.101:5000/led/all';

  // --- Toggle individual LED ---
  Future<void> toggleLed(int index, bool? newState) async {
    final state = newState ?? !leds[index];
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'index': index, 'state': state}),
      );
      if (response.statusCode == 200) {
        setState(() => leds[index] = state);
      }
    } catch (e) {
      print('Error toggling LED $index: $e');
    }
  }

  // --- Toggle all LEDs ---
  Future<void> toggleAll() async {
    final newState = !allOn;
    try {
      final response = await http.post(
        Uri.parse(baseAllUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': newState}),
      );
      if (response.statusCode == 200) {
        setState(() {
          allOn = newState;
          leds = List.filled(6, newState);
        });
      }
    } catch (e) {
      print('Error toggling all LEDs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC400),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/chick_icon.png', height: 35),
                const Text(
                  'LED Control',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LED Control Card
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

                    // All LEDs button
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

                    // Individual LEDs
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
                        itemBuilder: (context, i) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: leds[i]
                                ? Colors.green[500]
                                : Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => toggleLed(i, null),
                          child: Text(
                            'LED ${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
