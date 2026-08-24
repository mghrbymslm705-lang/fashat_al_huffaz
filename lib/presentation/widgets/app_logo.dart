import 'package:flutter/material.dart';

/// شعار التطبيق: مجموعة أطفال يلعبون تحت اسم "فسحة الحفّاظ".
///
/// يُستخدم في:
/// - صفحة "حول التطبيق" (داخل التطبيق).
/// - توليد أيقونة التطبيق (سطح المكتب / الهاتف) عبر أداة التصيير.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.background = true,
    this.showTitle = true,
    this.repaintKey,
  });

  /// حجم الشعار (مربّع).
  final double size;

  /// رسم الخلفية المتدرجة المستديرة (أو شفافة لأيقونة الـ adaptive).
  final bool background;

  /// عرض اسم التطبيق أسفل المشهد.
  final bool showTitle;

  /// مفتاح لالتقاط الصورة عند التصيير.
  final GlobalKey? repaintKey;

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(
      key: repaintKey,
      child: CustomPaint(
        painter: _ChildrenPlayingPainter(foreground: !background),
        size: Size.square(size),
        child: SizedBox.square(
          dimension: size,
          child: showTitle
              ? Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      left: size * 0.07,
                      right: size * 0.07,
                      bottom: size * 0.045,
                      child: Container(
                        height: size * 0.145,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D),
                          borderRadius: BorderRadius.circular(size * 0.07),
                        ),
                        child: Text(
                          'فسحة الحفّاظ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w700,
                            fontSize: size * 0.105,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );

    if (!background) return child;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFFA7F3D0)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: child,
    );
  }
}

/// يرسم مشهد أطفال يلعبون: سماء، شمس، أطفال، كرة، وعشب.
///
/// عند تفعيل [foreground] تُرسم العناصر فقط (خلفية شفافة) في منتصف
/// المربّع داخل المنطقة الآمنة لأيقونات Android adaptive.
class _ChildrenPlayingPainter extends CustomPainter {
  const _ChildrenPlayingPainter({required this.foreground});

  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    if (!foreground) {
      _paintScene(canvas, size, fullWidth: true);
      return;
    }

    // وضع أيقونة adaptive: مشهد مصغّر متمركز.
    final safe = size.shortestSide * 0.62;
    final sceneSize = Size.square(safe);
    final topLeft = Offset(
      (size.width - safe) / 2,
      (size.height - safe) / 2,
    );
    canvas.save();
    canvas.translate(topLeft.dx, topLeft.dy);
    _paintScene(canvas, sceneSize, fullWidth: false);
    canvas.restore();
  }

  void _paintScene(Canvas canvas, Size size, {required bool fullWidth}) {
    // --- السماء (تدرّج) ---
    if (!foreground) {
      final sky = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7DD3FC), Color(0xFFA7F3D0)],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, sky);
    }

    final w = size.width;
    final h = size.height;

    // --- الشمس ---
    if (!foreground) {
      final sunCenter = Offset(w * 0.82, h * 0.15);
      final sunR = w * 0.075;
      final ray = Paint()
        ..color = const Color(0xFFFBBF24)
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = i * 3.14159265 / 4;
        final start = sunCenter + Offset.fromDirection(angle, sunR * 1.15);
        final end = sunCenter + Offset.fromDirection(angle, sunR * 1.5);
        canvas.drawLine(start, end, ray);
      }
      canvas.drawCircle(
        sunCenter,
        sunR,
        Paint()..color = const Color(0xFFFDE047),
      );
    }

    // --- العشب ---
    final grassTop = h * (foreground ? 0.80 : 0.82);
    final grassRect = Rect.fromLTRB(0, grassTop, w, h);
    canvas.drawRect(
      grassRect,
      Paint()..color = const Color(0xFF22C55E),
    );
    if (!foreground) {
      // تلال عشب صغيرة على الحافة العلوية.
      final hill = Paint()..color = const Color(0xFF4ADE80);
      final bumps = [0.12, 0.3, 0.48, 0.66, 0.84];
      for (final bx in bumps) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * bx, grassTop),
            width: w * 0.22,
            height: h * 0.05,
          ),
          hill,
        );
      }
    }

    // --- الكرة ---
    final ballCenter = Offset(w * 0.545, grassTop - h * 0.035);
    final ballR = w * 0.045;
    canvas.drawCircle(ballCenter, ballR, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(
      ballCenter,
      ballR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008
        ..color = const Color(0xFFDC2626),
    );
    final seam = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.007
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(ballCenter.dx - ballR * 0.9, ballCenter.dy + ballR * 0.4),
      Offset(ballCenter.dx + ballR * 0.5, ballCenter.dy - ballR * 0.7),
      seam,
    );
    canvas.drawLine(
      Offset(ballCenter.dx + ballR * 0.2, ballCenter.dy - ballR * 0.95),
      Offset(ballCenter.dx - ballR * 0.35, ballCenter.dy + ballR * 0.9),
      seam,
    );

    // --- الأطفال ---
    final feetY = grassTop - h * 0.005;

    _drawChild(
      canvas,
      feet: Offset(w * 0.30, feetY),
      unit: h * 0.30,
      skin: const Color(0xFFF5C9A0),
      hair: const Color(0xFF3E2C22),
      shirt: const Color(0xFF3B82F6),
      pants: const Color(0xFF334155),
      hairPigtails: false,
      pose: _Pose.cheer,
      flipped: true,
    );

    _drawChild(
      canvas,
      feet: Offset(w * 0.52, feetY),
      unit: h * 0.36,
      skin: const Color(0xFFEDB47F),
      hair: const Color(0xFF8A5A2B),
      shirt: const Color(0xFFEF4444),
      pants: const Color(0xFF475569),
      hairPigtails: true,
      pose: _Pose.kick,
      flipped: false,
    );

    _drawChild(
      canvas,
      feet: Offset(w * 0.73, feetY),
      unit: h * 0.30,
      skin: const Color(0xFFD9A066),
      hair: const Color(0xFF3E2C22),
      shirt: const Color(0xFFF59E0B),
      pants: const Color(0xFF334155),
      hairPigtails: false,
      pose: _Pose.run,
      flipped: true,
    );
  }

  void _drawChild(
    Canvas canvas, {
    required Offset feet,
    required double unit,
    required Color skin,
    required Color hair,
    required Color shirt,
    required Color pants,
    required bool hairPigtails,
    required _Pose pose,
    required bool flipped,
  }) {
    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    if (flipped) canvas.scale(-1, 1);

    final headR = unit * 0.15;
    final shoulderY = -unit * 0.70;
    final hipY = -unit * 0.40;
    final headCenter = Offset(0, shoulderY + unit * 0.06 - headR);
    final legLen = -hipY;
    final armLen = unit * 0.30;

    final limb = Paint()
      ..strokeCap = StrokeCap.round
      ..color = pants;
    final arm = Paint()
      ..strokeCap = StrokeCap.round
      ..color = shirt;

    final legW = unit * 0.10;
    final armW = unit * 0.095;
    final shirtW = unit * 0.23;

    // الأرجل (الخلفية ثم الأمامية).
    ({double left, double right}) legAngles = switch (pose) {
      _Pose.cheer => (left: 0.12, right: -0.12),
      _Pose.kick => (left: -0.30, right: 0.45),
      _Pose.run => (left: 0.5, right: -0.5),
    };
    ({double left, double right}) armAngles = switch (pose) {
      _Pose.cheer => (left: 3.05, right: 3.05),
      _Pose.kick => (left: 0.5, right: 2.9),
      _Pose.run => (left: 2.5, right: 0.6),
    };

    _drawLimb(
      canvas,
      start: Offset(0, hipY),
      angle: legAngles.left,
      length: legLen,
      width: legW,
      paint: limb,
    );
    _drawLimb(
      canvas,
      start: Offset(0, hipY),
      angle: legAngles.right,
      length: legLen,
      width: legW,
      paint: limb,
    );

    // الجسد (قميص).
    final bodyRect = Rect.fromCenter(
      center: Offset(0, (hipY + shoulderY) / 2),
      width: shirtW,
      height: hipY - shoulderY,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(unit * 0.07)),
      Paint()..color = shirt,
    );

    // الذراعان.
    _drawLimb(
      canvas,
      start: Offset(-shirtW * 0.32, shoulderY),
      angle: armAngles.left,
      length: armLen,
      width: armW,
      paint: arm,
    );
    _drawLimb(
      canvas,
      start: Offset(shirtW * 0.32, shoulderY),
      angle: armAngles.right,
      length: armLen,
      width: armW,
      paint: arm,
    );

    // الرأس.
    canvas.drawCircle(headCenter, headR, Paint()..color = skin);

    // الشعر.
    final hairPaint = Paint()..color = hair;
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR),
      3.14159265,
      3.14159265,
      true,
      hairPaint,
    );
    if (hairPigtails) {
      final bun = Paint()..color = hair;
      final bunR = headR * 0.28;
      canvas.drawCircle(
        headCenter.translate(-headR * 0.92, headR * 0.1),
        bunR,
        bun,
      );
      canvas.drawCircle(
        headCenter.translate(headR * 0.92, headR * 0.1),
        bunR,
        bun,
      );
    }

    // وجه مبتسم.
    final smile = Paint()
      ..color = const Color(0xFF8A4B2A)
      ..strokeWidth = headR * 0.16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(
        center: headCenter.translate(0, headR * 0.15),
        radius: headR * 0.55,
      ),
      0.25,
      2.6,
      false,
      smile,
    );

    canvas.restore();
  }

  void _drawLimb(
    Canvas canvas, {
    required Offset start,
    required double angle,
    required double length,
    required double width,
    required Paint paint,
  }) {
    final end = start + Offset.fromDirection(angle, length);
    canvas.drawLine(start, end, paint..strokeWidth = width);
  }

  @override
  bool shouldRepaint(covariant _ChildrenPlayingPainter oldDelegate) =>
      oldDelegate.foreground != foreground;
}

enum _Pose { cheer, kick, run }
