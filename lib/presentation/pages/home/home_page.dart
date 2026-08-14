import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/category.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/category_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../details/activity_detail_page.dart';

/// الصفحة الرئيسية: ترويسة، بطاقة Hero للاقتراح، تابع من حيث توقفت،
/// إحصاءات مختصرة، استكشاف الأنشطة، اختيار اليوم، وأنشطة مقترحة.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpenSuggest});

  /// يُستدعى للانتقال إلى تبويب "اقترح لي نشاطًا".
  final VoidCallback? onOpenSuggest;

  @override
  Widget build(BuildContext context) {
    final lastUsed =
        context.select<ActivityProvider, Activity?>((p) => p.lastUsedActivity);
    final lastUsedAt =
        context.select<ActivityProvider, DateTime?>((p) => p.lastUsedAt);
    final dailyPick =
        context.select<ActivityProvider, Activity?>((p) => p.activityOfTheDay);
    final suggested = context.select<ActivityProvider, List<Activity>>(
        (p) => p.suggestedActivities);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              const _HomeHeader(),
              const SizedBox(height: 14),
              _HeroSuggestBanner(onTap: onOpenSuggest),
              if (lastUsed != null) ...[
                const SizedBox(height: 14),
                _ContinueCard(activity: lastUsed, lastUsedAt: lastUsedAt),
              ],
              const SizedBox(height: 14),
              const _StatsBar(),
              const SizedBox(height: 14),
              const _LoadStatus(),
              const SizedBox(height: 8),
              const SectionHeader(
                title: '📚 استكشف الأنشطة',
                subtitle: 'اختر قسمًا لاستعراض أنشطته',
              ),
              const SizedBox(height: 8),
              const _CategoriesGrid(),
              if (dailyPick != null) ...[
                const SizedBox(height: 18),
                const SectionHeader(
                  title: '🌟 اختيار اليوم',
                  subtitle: 'نشاط مختار خصيصًا لليوم',
                ),
                const SizedBox(height: 8),
                _ChoiceOfDayCard(activity: dailyPick),
              ],
              if (suggested.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionHeader(
                  title: '⭐ أنشطة مقترحة لك',
                  subtitle: 'اخترناها من مكتبتك لتناسبك',
                ),
                const SizedBox(height: 8),
                _SuggestedRow(activities: suggested),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ترويسة الترحيب مع شعار التطبيق.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فسحة الحفاظ 🌿',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
              ),
              SizedBox(height: 2),
              Text(
                'نتعلم، نحفظ، ونستمتع بالطريق.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// بطاقة Hero للاقتراح: التدرج الأخضر/البرتقالي + خيارات سريعة.
class _HeroSuggestBanner extends StatelessWidget {
  const _HeroSuggestBanner({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.primary, AppColors.orange],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.casino_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎲 ماذا تريد أن تفعل اليوم؟',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'دع فسحة الحفاظ تختار لك نشاطًا مناسبًا.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _QuickChip(label: '📖 حفظ'),
                    const _QuickChip(label: '🔄 مراجعة'),
                    const _QuickChip(label: '🏆 تحدٍّ'),
                    const _QuickChip(label: '🏃 حركي'),
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('✨ اختر لي'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB45309),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شارة اختيار سريع داخل بطاقة الاقتراح.
class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// بطاقة "تابع من حيث توقفت": آخر نشاط فتحه المستخدم.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.activity, this.lastUsedAt});

  final Activity activity;
  final DateTime? lastUsedAt;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final category = provider.categoryFor(activity.category);
    final accent = category?.colorValue ?? AppColors.primary;

    void openDetails() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailPage(activity: activity),
        ),
      );
    }

    return _TapScale(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: openDetails,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconResolver.resolve(category?.icon),
                          size: 20,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '📌 تابع من حيث توقفت',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (lastUsedAt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'آخر استخدام · ${_timeAgo(lastUsedAt!)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: openDetails,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('متابعة النشاط'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نص عربي مبسط لوصف الزمن الماضي ("منذ ...").
String _timeAgo(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inHours < 1) {
    final m = diff.inMinutes;
    if (m == 1) return 'منذ دقيقة واحدة';
    if (m == 2) return 'منذ دقيقتين';
    return 'منذ $m دقيقة';
  }
  if (diff.inDays < 1) {
    final h = diff.inHours;
    if (h == 1) return 'منذ ساعة واحدة';
    if (h == 2) return 'منذ ساعتين';
    return 'منذ $h ساعة';
  }
  final d = diff.inDays;
  if (d == 1) return 'منذ يوم واحد';
  if (d == 2) return 'منذ يومين';
  if (d < 11) return 'منذ $d أيام';
  return 'منذ $d يوم';
}

/// شريط الإحصاءات المختصر: معلومات ثانوية لا تُزاحم الأنشطة.
class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final total = context.select<ActivityProvider, int>((p) => p.totalCount);
    final sectionCount =
        context.select<ActivityProvider, int>((p) => p.categories.length);
    final favoriteCount =
        context.select<ActivityProvider, int>((p) => p.favoriteCount);

    final stats = [
      (icon: IconResolver.resolve('menu_book'), label: 'نشاطًا', value: total),
      (icon: IconResolver.resolve('folder'), label: 'قسم', value: sectionCount),
      (
        icon: IconResolver.resolve('favorite'),
        label: 'مفضل',
        value: favoriteCount,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final s in stats)
            Expanded(
              child: Column(
                children: [
                  Icon(s.icon, size: 13, color: AppColors.textSecondary),
                  const SizedBox(height: 3),
                  Text(
                    '${s.value} ${s.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// حالة التحميل: شريط تقدم + رسالة خطأ (تُعرض عند الحاجة فقط).
class _LoadStatus extends StatelessWidget {
  const _LoadStatus();

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<ActivityProvider, bool>((p) => p.isLoading);
    final error = context.select<ActivityProvider, String?>((p) => p.error);

    return Column(
      children: [
        if (isLoading) const LinearProgressIndicator(),
        if (error != null) _ErrorCard(message: error),
      ],
    );
  }
}

/// شبكة بطاقات الأقسام (عمودان على الهاتف، ثلاثة على الشاشات الواسعة).
class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final categories =
        context.select<ActivityProvider, List<Category>>((p) => p.categories);

    if (categories.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'لا توجد أقسام بعد',
        message: 'تأكد من وجود ملف categories.json داخل مجلد الأصول.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: itemWidth,
                child: _TapScale(
                  child: CategoryCard(
                    category: category,
                    count: provider.categoryCount(category.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// بطاقة "اختيار اليوم": نشاط واحد يُختار يوميًا من التاريخ.
class _ChoiceOfDayCard extends StatelessWidget {
  const _ChoiceOfDayCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final category = provider.categoryFor(activity.category);

    void openDetails() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailPage(activity: activity),
        ),
      );
    }

    return _TapScale(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              AppColors.gold.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: openDetails,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (activity.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                activity.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: category.colorValue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: category.colorValue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: openDetails,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('ابدأ النشاط'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صف أفقي للأنشطة المقترحة: بطاقات صغيرة تتنقل أفقيًا.
class _SuggestedRow extends StatelessWidget {
  const _SuggestedRow({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: 260,
          child: _SuggestedCard(activity: activities[index]),
        ),
      ),
    );
  }
}

/// بطاقة نشاط مقترح صغيرة تفتح صفحة التفاصيل.
class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final category = provider.categoryFor(activity.category);
    final accent = category?.colorValue ?? AppColors.primary;
    final icon = IconResolver.resolve(category?.icon);

    return _TapScale(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActivityDetailPage(activity: activity),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 22, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        if (activity.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            activity.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// غلاف تفاعل خفيف: ضغط بسيط + hover ناعم على سطح المكتب.
///
/// لا يمسّ نقر [InkWell] الداخلي ولا حركته؛ يضيف إحساسًا لمسيًا فقط.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.child});

  final Widget child;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.975 : (_hovered ? 1.015 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// بطاقة خطأ التحميل.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
