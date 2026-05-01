import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static bool _isPlaying = false;

  /// 🔊 播放一次
  static Future<void> playOnce() async {
    await _player.stop();

    await _player.play(
      AssetSource('sounds/ring.mp3'),
    );
  }

  /// 🔥 循环播放（来电效果）
  static Future<void> startLoop() async {
    if (_isPlaying) return;

    _isPlaying = true;

    await _player.setReleaseMode(ReleaseMode.loop);

    await _player.play(
      AssetSource('sounds/ring.mp3'),
    );
  }

  /// ⛔ 停止播放
  static Future<void> stop() async {
    _isPlaying = false;
    await _player.stop();
  }
}