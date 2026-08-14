import 'package:shared_preferences/shared_preferences.dart';

/// طبقة الوصول إلى الإعدادات المحلية (SharedPreferences).
///
/// تُستخدم لحفظ: المفضلة، وضع العرض (ليلي/نهاري)، حجم الخط.
/// الإعدادات والتفضيلات لا تُكتب أبدًا داخل ملفات المحتوى الأصلية.
class PrefsDatasource {
  static const String kFavorites = 'favorite_ids';
  static const String kFavoritesInitialized = 'favorites_initialized';
  static const String kThemeMode = 'theme_mode';
  static const String kFontScale = 'font_scale';
  static const String kLastActivityId = 'last_activity_id';
  static const String kLastActivityAt = 'last_activity_at';

  // -------------------- المفضلة --------------------

  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(kFavorites) ?? const []).toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kFavorites, ids.toList());
  }

  Future<bool> isFavoritesInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kFavoritesInitialized) ?? false;
  }

  Future<void> markFavoritesInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kFavoritesInitialized, true);
  }

  // -------------------- وضع العرض --------------------

  Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kThemeMode);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kThemeMode, mode);
  }

  // -------------------- حجم الخط --------------------

  Future<double> loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(kFontScale) ?? 1.0;
  }

  Future<void> saveFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kFontScale, scale);
  }

  // -------------------- آخر نشاط مستخدم --------------------

  /// معرّف آخر نشاط فتحه المستخدم (يظهر في "تابع من حيث توقفت").
  Future<String?> loadLastActivityId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLastActivityId);
  }

  Future<String?> loadLastActivityAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLastActivityAt);
  }

  Future<void> saveLastActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastActivityId, id);
    await prefs.setString(kLastActivityAt, DateTime.now().toIso8601String());
  }
}
