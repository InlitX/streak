import 'package:audioplayers/audioplayers.dart';
import 'package:streak/core/database/local_store.dart';

class CheckSound {
  const CheckSound._();

  static AudioPlayer? _player;

  static Future<void> play() async {
    if (!LocalStore.setting('checkSound', false)) return;
    try {
      var player = _player;
      if (player == null) {
        player = _player = AudioPlayer();
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.none,
            ),
            iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          ),
        );
        await player.setVolume(0.6);
      }
      await player.stop();
      await player.play(AssetSource('sounds/chime.mp3'));
    } catch (_) {}
  }
}
