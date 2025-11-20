  import 'package:flutter/material.dart';
  import 'package:flutter_vlc_player/flutter_vlc_player.dart';

  class LiveFeedPage extends StatefulWidget {
    const LiveFeedPage({super.key});

    @override
    State<LiveFeedPage> createState() => _LiveFeedPageState();
  }

  class _LiveFeedPageState extends State<LiveFeedPage> {
    late VlcPlayerController _vlcController;

    final String _streamUrl = 'rtsp://192.168.1.89:8554/eggstream';

    @override
    void initState() {
      super.initState();
      _vlcController = VlcPlayerController.network(
        _streamUrl,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );
    }

    @override
    void dispose() {
      _vlcController.stop();
      _vlcController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFC400),
          title: const Text('Live Egg Feed'),
        ),
        body: Center(
          child: VlcPlayer(
            controller: _vlcController,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
  }
