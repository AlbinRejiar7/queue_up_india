import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class InAppAlertService {
  InAppAlertService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> notify() async {
    if (_isPlaying) {
      return;
    }
    _isPlaying = true;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 150);
      }
      await _player.play(
        AssetSource(
          'ringtone/dragon-studio-notification-sound-effect-372475.mp3',
        ),
      );
    } finally {
      _isPlaying = false;
    }
  }
}
