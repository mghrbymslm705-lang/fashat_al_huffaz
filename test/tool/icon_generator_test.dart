import 'dart:io';
import 'dart:ui' as ui;

import 'package:fashat_al_huffaz/presentation/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// أداة توليد أيقونة التطبيق من شعار [AppLogo].
///
/// التشغيل:
///   flutter test test/tool/icon_generator_test.dart
///
/// يُنتج:
///   assets/icon/app_icon.png          (أيقونة كاملة بخلفية + اسم التطبيق)
///   assets/icon/app_icon_foreground.png (عناصر فقط بخلفية شفافة للـ adaptive)
void main() {
  testWidgets('توليد أيقونة التطبيق', (tester) async {
    // تحميل خط Tajawal حتى يُعرض الاسم العربي فعليًا وليس بصناديق اختبار.
    final fontData = await rootBundle.load('assets/fonts/Tajawal-Black.ttf');
    final loader = FontLoader('Tajawal')..addFont(Future.value(fontData));
    await loader.load();

    const size = 1024.0;
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fullKey = GlobalKey();
    final fgKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: AppLogo(size: size, repaintKey: fullKey),
          ),
        ),
      ),
    );
    await tester.pump();

    // الأيقونة الكاملة.
    await tester.runAsync(() async {
      final boundary =
          fullKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('assets/icon/app_icon.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // عناصر الـ adaptive foreground (خلفية شفافة).
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: AppLogo(
              size: size,
              background: false,
              showTitle: false,
              repaintKey: fgKey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          fgKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('assets/icon/app_icon_foreground.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });

    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
    expect(File('assets/icon/app_icon_foreground.png').existsSync(), isTrue);
  });
}
