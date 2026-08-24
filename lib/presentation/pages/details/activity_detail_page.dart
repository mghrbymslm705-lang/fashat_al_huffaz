import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/enums/location_type.dart';
import '../../../core/enums/movement_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_launcher.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../domain/entities/activity.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/info_chip.dart';

/// صفحة تفاصيل النشاط: كل المعلومات المتوفرة في ملف المحتوى
/// بالإضافة إلى زر "مشاهدة الشرح" الذي يفتح رابط الفيديو حصريًا.
class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final Activity activity;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  Activity get activity => widget.activity;

  @override
  void initState() {
    super.initState();
    // تسجيل هذا النشاط كآخر نشاط استُخدم (يظهر في "تابع من حيث توقفت").
    context.read<ActivityProvider>().markActivityUsed(activity.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final accent = provider.categoryFor(activity.category)?.colorValue ??
        AppColors.primary;
    final isFavorite = provider.isFavorite(activity.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _DetailHeader(
            activity: activity,
            accent: accent,
            isFavorite: isFavorite,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleBlock(activity: activity),
                  const SizedBox(height: 12),
                  _InfoChipsRow(activity: activity),
                  const SizedBox(height: 8),
                  if (activity.description.isNotEmpty)
                    _DetailSection(
                      title: 'نبذة عن النشاط',
                      icon: Icons.description_rounded,
                      child: Text(
                        activity.description,
                        style: const TextStyle(height: 1.7, fontSize: 14),
                      ),
                    ),
                  if (activity.goal.isNotEmpty)
                    _DetailSection(
                      title: 'الهدف التربوي',
                      icon: Icons.flag_rounded,
                      accent: AppColors.primaryDark,
                      child: Text(
                        activity.goal,
                        style: const TextStyle(height: 1.7, fontSize: 14),
                      ),
                    ),
                  if (activity.tools.isNotEmpty)
                    _DetailSection(
                      title: 'الأدوات المطلوبة',
                      icon: Icons.handyman_rounded,
                      accent: AppColors.orange,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: activity.tools
                            .map((t) => Chip(
                                  label: Text(t),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ),
                  if (activity.steps.isNotEmpty)
                    _DetailSection(
                      title: 'خطوات التنفيذ',
                      icon: Icons.format_list_numbered_rounded,
                      accent: AppColors.blue,
                      child: Column(
                        children: [
                          for (var i = 0; i < activity.steps.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activity.steps[i],
                                      style: const TextStyle(
                                          height: 1.6, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (activity.benefits.isNotEmpty)
                    _DetailSection(
                      title: 'فوائد النشاط',
                      icon: Icons.workspace_premium_rounded,
                      accent: AppColors.gold,
                      child: _BulletList(
                        items: activity.benefits,
                        color: AppColors.gold,
                      ),
                    ),
                  if (activity.tips.isNotEmpty)
                    _DetailSection(
                      title: 'نصائح للمشرف',
                      icon: Icons.lightbulb_rounded,
                      accent: AppColors.teal,
                      child: _BulletList(
                        items: activity.tips,
                        color: AppColors.teal,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SourceBox(activity: activity, isDark: isDark),
                  const SizedBox(height: 16),
                  _WatchButton(activity: activity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رأس الصفحة: تدرج لوني + أيقونة + زر المفضلة.
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.activity,
    required this.accent,
    required this.isFavorite,
  });

  final Activity activity;
  final Color accent;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final icon = IconResolver.resolve(
      provider.categoryFor(activity.category)?.icon,
    );

    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [accent, Color.lerp(accent, Colors.black, 0.3)!],
            ),
          ),
          child: Center(
            child: Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.92)),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'المفضلة',
          onPressed: () => provider.toggleFavorite(activity.id),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : Colors.white,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// العنوان مع شارة النموذج التجريبي وذكر المصدر.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activity.isDemo)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              AppConstants.demoBadge,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        if (activity.source.file.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.source_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'المصدر: ${activity.source.fullLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// صف شرائح المعلومات الأساسية.
class _InfoChipsRow extends StatelessWidget {
  const _InfoChipsRow({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      InfoChip(
        icon: Icons.child_care_rounded,
        label: !activity.age.isUnspecified
            ? '${activity.age.label} سنة'
            : 'كل الأعمار',
        color: AppColors.blue,
      ),
      InfoChip(
        icon: Icons.people_rounded,
        label: !activity.participants.isUnspecified
            ? '${activity.participants.label} مشارك'
            : 'المشاركون',
        color: AppColors.purple,
      ),
      InfoChip(
        icon: Icons.timer_rounded,
        label: !activity.duration.isUnspecified
            ? '${activity.duration.label} دقيقة'
            : 'الزمن',
        color: AppColors.orange,
      ),
      InfoChip(
        icon: IconResolver.forMovement(activity.movement),
        label: activity.movement.label,
        color: activity.movement == MovementLevel.active
            ? AppColors.orange
            : AppColors.teal,
      ),
      InfoChip(
        icon: IconResolver.forLocation(activity.location),
        label: activity.location == LocationType.any
            ? 'داخل أو خارج'
            : activity.location.label,
        color: AppColors.primary,
      ),
    ];

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

/// بطاقة قسم داخل التفاصيل.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = AppColors.primary,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// قائمة نقطية.
class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.color});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 8, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item, style: const TextStyle(height: 1.6, fontSize: 14)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// بطاقة مرجع المصدر الأصلي.
class _SourceBox extends StatelessWidget {
  const _SourceBox({required this.activity, required this.isDark});

  final Activity activity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasSource = activity.source.file.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSource
                      ? 'جاء هذا النشاط من الملف: ${activity.source.fullLabel}'
                      : 'المحتوى مأخوذ من ملفات مكتبتك',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (hasSource && activity.source.isExternalUrl) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => AppLauncher.openUrl(context, activity.source.file),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 42),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('تحميل/فتح المصدر'),
            ),
          ],
        ],
      ),
    );
  }
}

/// الزر الرئيسي لفتح شرح النشاط (الاستخدام الوحيد للإنترنت).
class _WatchButton extends StatelessWidget {
  const _WatchButton({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    if (!activity.hasVideo) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'لا يوجد شرح مرئي لهذا النشاط حاليًا.\nيمكنك إضافة رابط الشرح في ملف المحتوى.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => AppLauncher.openUrl(context, activity.videoUrl),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
      label: const Text('مشاهدة الشرح'),
    );
  }
}
