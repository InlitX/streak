import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class FocusTrack {
  const FocusTrack({
    required this.id,
    required this.name,
    required this.asset,
  });

  final String id;
  final String name;
  final bool asset;

  Source get source =>
      asset ? AssetSource('sounds/$id') : DeviceFileSource(id);

  String encode() => '$id|$name';

  static FocusTrack? decode(String raw) {
    final index = raw.indexOf('|');
    if (index <= 0) return null;
    final path = raw.substring(0, index);
    if (!File(path).existsSync()) return null;
    return FocusTrack(
      id: path,
      name: raw.substring(index + 1),
      asset: false,
    );
  }
}

const builtInTracks = <String, String>{
  'rain.mp3': 'Rain',
  'one_love.mp3': 'One Love',
  'i_can_find_you.mp3': 'I Can Find You',
};

class FocusAudio {
  const FocusAudio._();

  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _effects = AudioPlayer();
  static final Random _random = Random();

  static final ValueNotifier<String> current = ValueNotifier('');
  static final ValueNotifier<bool> playing = ValueNotifier(false);

  static List<FocusTrack> _queue = const [];
  static bool _shuffle = false;
  static bool _wired = false;

  static const maxTracks = 10;

  static const trackExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'flac',
    'mp4',
  ];
  static const maxTrackMinutes = 20;

  static void _wire() {
    if (_wired) return;
    _wired = true;
    _player.onPlayerComplete.listen((_) => _advance());
  }

  static Future<void> _advance() async {
    if (_queue.isEmpty) return;
    if (_queue.length == 1) {
      await _start(_queue.first);
      return;
    }
    final index = _queue.indexWhere((t) => t.id == current.value);
    final next = _shuffle
        ? _pickRandom(index)
        : (index + 1) % _queue.length;
    await _start(_queue[next]);
  }

  static int _pickRandom(int avoid) {
    if (_queue.length < 2) return 0;
    var next = avoid;
    while (next == avoid) {
      next = _random.nextInt(_queue.length);
    }
    return next;
  }

  static Future<void> _start(FocusTrack track) async {
    _wire();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(track.source);
    current.value = track.id;
    playing.value = true;
  }

  static Future<void> playQueue(
    List<FocusTrack> tracks, {
    required bool shuffle,
    FocusTrack? from,
  }) async {
    if (tracks.isEmpty) return;
    _queue = tracks;
    _shuffle = shuffle;
    final start = from ??
        (shuffle ? tracks[_random.nextInt(tracks.length)] : tracks.first);
    await _start(start);
  }

  static Future<void> pause() async {
    await _player.pause();
    playing.value = false;
  }

  static Future<void> resume() async {
    await _player.resume();
    playing.value = true;
  }

  static Future<void> stop() async {
    await _player.stop();
    playing.value = false;
    current.value = '';
  }

  static Future<void> chime() async {
    try {
      await _effects.stop();
      await _effects.play(AssetSource('sounds/chime.wav'), volume: 0.9);
    } catch (_) {}
  }

  static Future<int?> durationOf(String path) async {
    final probe = AudioPlayer();
    try {
      await probe.setSourceDeviceFile(path);
      final duration = await probe.getDuration();
      return duration?.inMinutes;
    } catch (_) {
      return null;
    } finally {
      await probe.dispose();
    }
  }
}
