import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_settings.dart';

/// Short sound effects. They mix with whatever the player is listening to
/// and stay quiet when the phone is on silent.
class GameSounds {
  GameSounds._();

  static AudioPlayer? _player;

  /// A bright little jingle for clearing an Arrow Escape level.
  static Future<void> levelClear() async {
    if (!GameSettings.sounds) return;
    try {
      final player = _player ??= await _newPlayer();
      await player.stop();
      await player.play(AssetSource('sounds/level_clear.wav'));
    } catch (error) {
      // A missing sound never stops the game.
      debugPrint('Sound unavailable: $error');
    }
  }

  static Future<AudioPlayer> _newPlayer() async {
    // iOS: the ambient category mixes in and obeys the Silent switch.
    // Android: a game sound that takes no audio focus, so music keeps on.
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    return AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }
}
