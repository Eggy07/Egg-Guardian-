import 'package:flutter/material.dart';

class LiveFeedPage extends StatelessWidget {
  const LiveFeedPage({super.key});

  // URL of your live feed from the Flask server
  final String _liveFeedUrl = 'http://192.168.1.73:5000/video_feed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('Live Egg Feed'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Live Camera Feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Display live feed
            Expanded(
              child: Center(
                child: Image.network(
                  _liveFeedUrl,
                  gaplessPlayback: true, // smoother MJPEG stream
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Failed to load live feed');
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
