import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BetterWhiteNoise());
}

class BetterWhiteNoise extends StatelessWidget {
  const BetterWhiteNoise({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better White Noise',
      theme: ThemeData.dark(),
      home: const AppHomePage(title: 'Better White Noise'),
    );
  }
}

class AppHomePage extends StatefulWidget {
  const AppHomePage({super.key, required this.title});

  //Fields in a Widget subclass are always marked "final".

  final String title;

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {

  final _players = <String, AudioPlayer>{};
  Map<String, double> _volumes = {
    "Rain": 0.0,
    "Wind": 0.0,
    "Crickets": 0.0,
    "Fireplace": 0.0,
    "Birds": 0.0,
    "River": 0.0,
    "Campfire": 0.0,
    "Music": 0.0,
    "Rainforest": 0.0,
    "Beach": 0.0,
    "Thunder": 0.0,
    "Ocean": 0.0,
    "White Noise": 0.0,
  };
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _loadVolumes().then((_) => _initPlayers());
  }

  Future<void> _loadVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volumes = {
        "Rain": prefs.getDouble("Rain") ?? 0.0,
        "Wind": prefs.getDouble("Wind") ?? 0.0,
        "Crickets": prefs.getDouble("Crickets") ?? 0.0,
        "Fireplace": prefs.getDouble("Fireplace") ?? 0.0,
        "Birds": prefs.getDouble("Birds") ?? 0.0,
        "River": prefs.getDouble("River") ?? 0.0,
        "Campfire": prefs.getDouble("Campfire") ?? 0.0,
        "Music": prefs.getDouble("Music") ?? 0.0,
        "Rainforest": prefs.getDouble("Rainforest") ?? 0.0,
        "Beach": prefs.getDouble("Beach") ?? 0.0,
        "Thunder": prefs.getDouble("Thunder") ?? 0.0,
        "Ocean": prefs.getDouble("Ocean") ?? 0.0,
        "White Noise": prefs.getDouble("White Noise") ?? 0.0,
      };
    });
  }

  Future<void> _saveVolume(String sound, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(sound, value);
  }

  Future<void> _initPlayers() async {
    for (final sound in _volumes.keys) {
      final player = AudioPlayer();
      await player.setLoopMode(LoopMode.all);
      final soundLower = sound.toLowerCase();
      await player.setAsset("assets/$soundLower.mp3");
      await player.setVolume(_volumes[sound]!);
      player.play();
      _players[sound] = player;
    }
  }

  Timer? _sleepTimer;
  Duration? _remaining;
  final int _fadeOutSeconds = 20;

  void _startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    setState(() {
      _remaining = duration;
    });

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _remaining = _remaining! - const Duration(seconds: 1);
      });

    if (_remaining!.inSeconds == _fadeOutSeconds) {
      _fadeOut();
    }

    if (_remaining!.inSeconds <= 0) {
      t.cancel();
      _pauseAll();
      _loadVolumes();
    }
    });
  }

  void _fadeOut() {
    // Step volumes down over time
    for (final sound in _players.keys) {
      final player = _players[sound]!;
      final startVol = _volumes[sound]!;
      int steps = _fadeOutSeconds;
      double stepSize = startVol / steps;

      for (int i = 0; i < steps; i++) {
        Future.delayed(Duration(seconds: i), () {
          final newVol = (startVol - stepSize * i).clamp(0.0, 1.0);
          player.setVolume(newVol);
        });
      }
    }
  }

  void _togglePlaying() {
    if (_isPlaying) {
      _pauseAll();
    } else {
      _unpauseAll();
    }
  }

  void _pauseAll() {
    for (final player in _players.values) {
      player.pause();
    }
    setState(() {_isPlaying = false;});
  }

  void _unpauseAll() {
    for (final player in _players.values) {
      player.play();
    }
    setState(() {_isPlaying = true;});
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _sleepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () async {
              final minutes = await showDialog<int>(
                context: context,
                builder: (context) {
                  int temp = 30;
                  return AlertDialog(
                    title: const Text("Set Timer Duration (minutes)"),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        return Slider(
                          value: temp.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          label: "$temp min",
                          onChanged: (v) => setState(() => temp = v.toInt()),
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                          Navigator.of(context).pop(null), //cancel
                        child: const Text("Cancel")),
                      TextButton(
                        onPressed: () =>
                          Navigator.of(context).pop(temp), //confirm
                        child: const Text("Set")),
                    ],
                  );
                },
              );

              if (minutes != null) {
                _startSleepTimer(Duration(minutes: minutes));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_remaining != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Timer: ${_remaining!.inMinutes}:${(_remaining!.inSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _volumes.keys.map((sound) {
                return Card (
                  child: ListTile(
                    title: Text(sound),
                    subtitle: Slider(
                      value: _volumes[sound]!,
                      onChanged: (v) {
                        setState(() {
                          _volumes[sound] = v;
                          _players[sound]?.setVolume(v);
                        });
                        _saveVolume(sound, v);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePlaying,
        tooltip: 'Mute / Unmute',
        child: Icon(_isPlaying ? Icons.volume_off : Icons.volume_up),
      ),
    );
  }
}
