import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزود إدارة الصوت: تشغيل تلقائي عند بدء التطبيق + تكرار مستمر + إيقاف يدوي.
class AudioProvider extends ChangeNotifier {
  AudioProvider() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  /// تهيئة المشغّل: يبحث عن ملف MP3 في assets/audio/ ويبدأ التشغيل التلقائي.
  Future<void> _init() async {
    try {
      // قراءة إعداد التشغيل من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('audio_enabled') ?? true;

      // محاولة تشغيل الملف الصوتي
      // اسم الملف الافتراضي: assets/audio/background.mp3
      // يمكن تغييره عن طريق وضع ملف MP3 آخر في المجلد
      await _player.setAsset('assets/audio/background.mp3');
      await _player.setLoopMode(LoopMode.one);

      if (enabled) {
        await _player.play();
        _isPlaying = true;
      }
    } catch (_) {
      // إذا لم يكن هناك ملف صوتي، نتجاهل الخطأ
      _isPlaying = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// تشغيل / إيقاف الصوت
  Future<void> toggle() async {
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
    } else {
      await _player.play();
      _isPlaying = true;
    }

    // حفظ الإعداد
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', _isPlaying);

    notifyListeners();
  }

  /// إيقاف الصوت
  Future<void> stop() async {
    await _player.pause();
    _isPlaying = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', false);
    notifyListeners();
  }

  /// تشغيل الصوت
  Future<void> play() async {
    await _player.play();
    _isPlaying = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', true);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
