import 'activity.dart';

/// نتيجة اقتراح من المساعد الذكي "اقترح لي نشاطًا".
///
/// يحمل النشاط مع درجة الملاءمة وأسباب الاقتراح (تُعرض للمستخدم).
/// يُبنى حصريًا من الأنشطة الموجودة في قاعدة البيانات المحلية.
class Suggestion {
  const Suggestion({
    required this.activity,
    required this.score,
    this.reasons = const [],
  });

  final Activity activity;

  /// درجة ملاءمة النشاط للمعايير.
  final int score;

  /// أسباب الاقتراح (نصوص قصيرة عربية).
  final List<String> reasons;

  /// هل النشاط ملائم (اجتاز كل الشروط الصارمة)؟
  bool get isValid => score > 0;

  /// كائن فاشل (درجة صفر) يُستخدم داخليًا عند عدم المطابقة.
  static Suggestion zero(Activity activity) =>
      Suggestion(activity: activity, score: 0);
}
