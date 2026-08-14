import 'package:flutter/material.dart';

import '../../data/datasources/prefs_datasource.dart';

/// مزوّد إعدادات التطبيق: وضع العرض وحجم الخط.
///
/// تُحفظ الإعدادات عبر [PrefsDatasource] لتظل محفوظة بين الجلسات.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this.prefs);

  final PrefsDatasource prefs;

  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;

  /// خيارات حجم الخط المتاحة.
  static const List<double> fontScaleOptions = [0.9, 1.0, 1.15, 1.3, 1.5];

  /// التسميات العربية لخيارات حجم الخط.
  static final Map<double, String> fontScaleLabels = {
    0.9: 'صغير',
    1.0: 'متوسط',
    1.15: 'كبير',
    1.3: 'أكبر',
    1.5: 'الأكبر',
  };

  ThemeMode get themeMode => _themeMode;

  double get fontScale => _fontScale;

  String get fontScaleLabel => fontScaleLabels[_fontScale] ?? 'متوسط';

  /// تحميل الإعدادات المحفوظة.
  Future<void> init() async {
    final savedMode = await prefs.loadThemeMode();
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );

    _fontScale = await prefs.loadFontScale();
    if (!fontScaleOptions.contains(_fontScale)) {
      _fontScale = 1.0;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await prefs.saveThemeMode(mode.name);
  }

  Future<void> setFontScale(double scale) async {
    if (scale == _fontScale) return;
    _fontScale = scale;
    notifyListeners();
    await prefs.saveFontScale(scale);
  }
}
