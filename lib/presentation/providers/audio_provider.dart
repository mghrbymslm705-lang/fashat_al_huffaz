import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// مزود إدارة الصوت: تشغيل عند طلب المستخدم + تكرار مستمر + إيقاف يدوي.
class AudioProvider extends ChangeNotifier {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  Future<void> _ensurePlayer() async {
    _player ??= AudioPlayer();
  }

  /// تشغيل الصوت (يدوي)
  Future<void> play() async {
    if (_isPlaying) return;
    try {
      await _ensurePlayer();
      if (_player!.playing) {
        await _player!.play();
      } else {
        await _player!.setUrl(
          'https://raw.githubusercontent.com/mghrbymslm705-lang/fashat_al_huffaz/main/assets/audio/background.mp3',
        );
        await _player!.setLoopMode(LoopMode.one);
        await _player!.play();
      }
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
    notifyListeners();
  }

  /// تشغيل / إيقاف الصوت (يدوي)
  Future<void> toggle() async {
    if (_isPlaying) {
      await _player?.pause();
      _isPlaying = false;
    } else {
      await play();
    }
    notifyListeners();
  }

  /// إيقاف الصوت (يدوي)
  Future<void> stop() async {
    await _player?.pause();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
