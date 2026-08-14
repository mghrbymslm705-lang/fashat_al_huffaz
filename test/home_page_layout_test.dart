import 'package:fashat_al_huffaz/data/datasources/local_activity_datasource.dart';
import 'package:fashat_al_huffaz/data/datasources/prefs_datasource.dart';
import 'package:fashat_al_huffaz/data/repositories/activity_repository_impl.dart';
import 'package:fashat_al_huffaz/presentation/pages/home/home_page.dart';
import 'package:fashat_al_huffaz/presentation/providers/activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('الصفحة الرئيسية تتجاوب بدون overflow على عدة عرضات',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsDatasource();
    final repository =
        ActivityRepositoryImpl(LocalActivityDatasource(prefs));
    final provider = ActivityProvider(repository, prefs);

    // تحميل المحتوى الحقيقي من الأصول (قراءة ملفات تتطلب runAsync).
    await tester.runAsync(() async {
      await provider.load();
      await provider.initLastActivity();
    });

    const widths = [360.0, 390.0, 430.0, 768.0, 1024.0, 1440.0];
    for (final width in widths) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'يجب ألا يوجد overflow عند عرض $width',
      );
    }
  });
}
