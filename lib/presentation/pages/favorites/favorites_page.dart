import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/movement_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../domain/entities/activity.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/empty_state.dart';
import '../details/activity_detail_page.dart';

/// صفحة المفضلة: الأنشطة التي أضافها المستخدم عبر زر القلب.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.onExplore});

  /// يُستدعى عند الضغط على "استكشاف الأنشطة" في الحالة الفارغة.
  final VoidCallback? onExplore;

  static String _countText(int count) {
    if (count == 1) return 'نشاط واحد';
    if (count == 2) return 'نشاطان';
    return '$count أنشطة';
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.select<ActivityProvider, List<Activity>>(
        (p) => p.favoriteActivities);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('المفضلة'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _countText(favorites.length),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
      body: favorites.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'لا توجد أنشطة في المفضلة بعد ❤️',
              message: 'استكشف الأنشطة وأضف ما يناسبك إلى هنا.',
              action: onExplore == null
                  ? null
                  : ElevatedButton.icon(
                      onPressed: onExplore,
                      icon: const Icon(Icons.explore_rounded),
                      label: const Text('استكشاف الأنشطة'),
                    ),
            )
          : _FavoritesGrid(favorites: favorites),
    );
  }
}

/// قائمة بطاقات المفضلة: عمود واحد على الهاتف وعمودان على الشاشات الكبيرة.
class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.favorites});

  final List<Activity> favorites;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 880;

              if (!isWide) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _FavoriteCard(activity: favorites[index]),
                );
              }

              final itemWidth = (constraints.maxWidth - 44) / 2;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final activity in favorites)
                      SizedBox(
                        width: itemWidth,
                        child: _FavoriteCard(activity: activity),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// بطاقة نشاط مفضل: أيقونة، اسم، وصف، شارات مختصرة، تصنيف الحركة، وزر البدء.
class _FavoriteCard extends StatefulWidget {
  const _FavoriteCard({required this.activity});

  final Activity activity;

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  bool _removing = false;

  Activity get activity => widget.activity;

  /// إزالة من المفضلة مع تأثير انقباض واضح قبل اختفاء البطاقة.
  Future<void> _remove() async {
    setState(() => _removing = true);
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    await context.read<ActivityProvider>().toggleFavorite(activity.id);
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(activity: activity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    final category = provider.categoryFor(activity.category);
    final accent = category?.colorValue ?? AppColors.primary;
    final icon = IconResolver.resolve(category?.icon);

    return AnimatedScale(
      scale: _removing ? 0.94 : 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _removing ? 0 : 1,
        duration: const Duration(milliseconds: 240),
        child: Card(
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            onTap: _openDetails,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, size: 26, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'إزالة من المفضلة',
                          onPressed: _remove,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                            size: 19,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 38,
                            minHeight: 38,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  if (activity.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniBadge(
                        icon: Icons.child_care_rounded,
                        label: !activity.age.isUnspecified
                            ? '${activity.age.label} سنة'
                            : 'كل الأعمار',
                      ),
                      _MiniBadge(
                        icon: Icons.timer_rounded,
                        label: !activity.duration.isUnspecified
                            ? '${activity.duration.label} دقيقة'
                            : 'المدة',
                      ),
                      _MiniBadge(
                        icon: Icons.people_rounded,
                        label: !activity.participants.isUnspecified
                            ? '${activity.participants.label} مشارك'
                            : 'مشاركون',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MovementTag(movement: activity.movement),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _openDetails,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('ابدأ النشاط'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
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
      ),
    );
  }
}

/// شارة معلومات صغيرة بألوان هادئة (العمر/المدة/المشاركون).
class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// تصنيف صغير مستقل لنوع النشاط (هادئة / حركية).
class _MovementTag extends StatelessWidget {
  const _MovementTag({required this.movement});

  final MovementLevel movement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconResolver.forMovement(movement),
            size: 13,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            movement.label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
