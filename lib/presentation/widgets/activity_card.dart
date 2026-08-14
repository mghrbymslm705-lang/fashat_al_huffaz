import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/movement_level.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_launcher.dart';
import '../../core/utils/icon_resolver.dart';
import '../../domain/entities/activity.dart';
import '../pages/details/activity_detail_page.dart';
import '../providers/activity_provider.dart';
import 'info_chip.dart';

/// بطاقة النشاط: تُستخدم في قوائم الأقسام والبحث والمفضلة ونتائج الاقتراح.
///
/// تحتوي على: صورة/أيقونة، الاسم، العمر، المشاركون، المدة، مستوى الحركة،
/// زر إضافة للمفضلة، وزر "مشاهدة الشرح".
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final category = provider.categoryFor(activity.category);
    final accent = category?.colorValue ?? AppColors.primary;
    final isFavorite = context.select<ActivityProvider, bool>(
        (p) => p.isFavorite(activity.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActivityDetailPage(activity: activity),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(activity: activity, accent: accent, isFavorite: isFavorite),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
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
                            : 'مشاركون',
                        color: AppColors.purple,
                      ),
                      InfoChip(
                        icon: Icons.timer_rounded,
                        label: !activity.duration.isUnspecified
                            ? '${activity.duration.label} دقيقة'
                            : 'المدة',
                        color: AppColors.orange,
                      ),
                      InfoChip(
                        icon: IconResolver.forMovement(activity.movement),
                        label: activity.movement.label,
                        color: activity.movement == MovementLevel.active
                            ? AppColors.orange
                            : AppColors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (activity.hasVideo)
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () =>
                                AppLauncher.openUrl(context, activity.videoUrl),
                            icon: const Icon(Icons.play_circle_rounded),
                            label: const Text('مشاهدة الشرح'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off_rounded,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 6),
                                Text(
                                  'بدون شرح مرئي',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconResolver.resolve(category.icon),
                                  size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رأس البطاقة: تدرج لوني، أيقونة/صورة، زر المفضلة، شارة النموذج التجريبي.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
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

    return Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
        ),
      ),
      child: Stack(
        children: [
          // الأيقونة الرئيسية (أو الصورة إن وُجدت).
          Positioned.fill(
            child: _ActivityVisual(activity: activity, accent: accent),
          ),
          // شارة النموذج التجريبي.
          if (activity.isDemo)
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  AppConstants.demoBadge,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          // زر المفضلة.
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () => provider.toggleFavorite(activity.id),
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.black54,
                  size: 20,
                ),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يعرض صورة النشاط إن وُجدت وإلا يعرض أيقونة القسم الكبيرة.
class _ActivityVisual extends StatelessWidget {
  const _ActivityVisual({required this.activity, required this.accent});

  final Activity activity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final category =
        context.read<ActivityProvider>().categoryFor(activity.category);
    final icon = IconResolver.resolve(category?.icon);

    if (activity.image.isEmpty) {
      return Icon(icon, size: 52, color: Colors.white.withValues(alpha: 0.9));
    }

    final imageUrl = activity.image;
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(icon),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackIcon(icon),
    );
  }

  Widget _fallbackIcon(IconData icon) =>
      Icon(icon, size: 52, color: Colors.white.withValues(alpha: 0.9));
}
