import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// مزود إدارة الصوت: تشغيل تلقائي عند فتح التطبيق + تكرار مستمر + إيقاف يدوي.
///
/// الصوت يعمل تلقائيًا كل مرة يُفتح فيها التطبيق.
/// الإيقاف فقط يدويًا من القائمة الجانبية.
class AudioProvider extends ChangeNotifier {
  AudioProvider() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  /// تهيئة المشغّل: يُشغّل الصوت تلقائيًا عند بدء التطبيق.
  Future<void> _init() async {
    try {
      await _player.setAsset('assets/audio/background.mp3');
      await _player.setLoopMode(LoopMode.one);

      // تشغيل تلقائي دائمًا عند فتح التطبيق
      await _player.play();
      _isPlaying = true;
    } catch (_) {
      // إذا لم يكن هناك ملف صوتي، نتجاهل الخطأ
      _isPlaying = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// تشغيل / إيقاف الصوت (يدوي)
  Future<void> toggle() async {
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
    } else {
      await _player.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  /// إيقاف الصوت (يدوي)
  Future<void> stop() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// تشغيل الصوت (يدوي)
  Future<void> play() async {
    await _player.play();
    _isPlaying = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
