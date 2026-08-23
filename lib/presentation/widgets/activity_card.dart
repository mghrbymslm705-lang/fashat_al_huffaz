import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/movement_level.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_launcher.dart';
import '../../core/utils/icon_resolver.dart';
import '../../domain/entities/activity.dart';
import '../pages/details/activity_detail_page.dart';
import '../providers/activity_provider.dart';
import 'info_chip.dart';

/// بطاقة النشاط: تصميم حيوي أنيق مع رأس متدرج ملوّن حسب القسم.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
              _CardHeader(
                activity: activity,
                accent: accent,
                isFavorite: isFavorite,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.35,
                        color:
                            isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
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
                              onPressed: () => AppLauncher.openUrl(
                                  context, activity.videoUrl),
                              icon: const Icon(Icons.play_circle_rounded,
                                  size: 18),
                              label: const Text('مشاهدة الشرح'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_off_rounded,
                                      size: 15,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'بدون شرح مرئي',
                                    style: TextStyle(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.5),
                                        fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    IconResolver.resolve(category.icon),
                                    size: 13,
                                    color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10.5,
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
      ),
    );
  }
}

/// رأس البطاقة: تدرج ناعم حسب لون القسم + أيقونة + زر المفضلة.
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
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: 0.75),
            Color.lerp(accent, Colors.black, 0.2)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _ActivityVisual(activity: activity, accent: accent),
          ),
          if (activity.isDemo)
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  AppConstants.demoBadge,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () =>
                    provider.toggleFavorite(activity.id),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? const Color(0xFFBF4F4F)
                      : Colors.black38,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      return Icon(icon,
          size: 48, color: Colors.white.withValues(alpha: 0.85));
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

  Widget _fallbackIcon(IconData icon) => Icon(icon,
      size: 48, color: Colors.white.withValues(alpha: 0.85));
}
