import 'package:flutter/material.dart';

import 'data/datasources/local_activity_datasource.dart';
import 'data/datasources/prefs_datasource.dart';
import 'data/repositories/activity_repository_impl.dart';
import 'presentation/app.dart';
import 'presentation/providers/activity_provider.dart';
import 'presentation/providers/settings_provider.dart';

/// نقطة دخول تطبيق "فسحة الحفّاظ".
///
/// - [PrefsDatasource] للإعدادات والمفضلة المحلية.
/// - [ActivityRepositoryImpl] مصدر المحتوى الوحيد (ملفات JSON محلية).
/// - التطبيق لا يتصل بأي خدمة خارجية للحصول على محتوى.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = PrefsDatasource();
  final settings = SettingsProvider(prefs);

  final repository = ActivityRepositoryImpl(LocalActivityDatasource(prefs));
  final activityProvider = ActivityProvider(repository, prefs);

  // تهيئة الإعدادات وآخر نشاط بالتوازي لتسريع الإقلاع.
  await Future.wait([
    settings.init(),
    activityProvider.initLastActivity(),
  ]);

  runApp(
    FashatApp(
      settings: settings,
      activityProvider: activityProvider,
    ),
  );
}
