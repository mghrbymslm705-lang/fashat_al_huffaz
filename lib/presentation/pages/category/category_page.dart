import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/category.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../filters/filter_page.dart';
import '../search/search_page.dart';

/// صفحة قسم: تعرض أنشطة القسم على شكل بطاقات، مع إمكانية التصفية.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final accent = category.colorValue;

    final hasFilter = context.select<ActivityProvider, bool>(
        (p) => p.hasActiveFilter);
    final filterCount = context.select<ActivityProvider, int>(
        (p) => p.activeFilterCount);
    final filtered = context.select<ActivityProvider, List<Activity>>(
        (p) => p.filteredResults);
    final provider = context.read<ActivityProvider>();

    // عند تفعيل الفلاتر تظهر النتائج المفلترة الخاصة بهذا القسم فقط.
    final results = hasFilter
        ? filtered.where((a) => a.category == category.id).toList()
        : provider.activitiesFor(category.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconResolver.resolve(category.icon), color: accent, size: 22),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
        actions: [
          // زر الفلاتر الذكية مع عداد للشروط المفعلة.
          Badge.count(
            count: filterCount,
            isLabelVisible: filterCount > 0,
            child: IconButton(
              tooltip: 'الفلاتر الذكية',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FilterPage()),
                );
              },
              icon: const Icon(Icons.filter_list_rounded),
            ),
          ),
          IconButton(
            tooltip: 'البحث',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchPage(category: category),
                ),
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (hasFilter) _ActiveFilterBar(count: filterCount),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد أنشطة هنا',
                    message: 'جرّب تغيير الفلاتر أو البحث في أقسام أخرى.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        ActivityCard(activity: results[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// شريط يوضح أن الفلاتر مفعلة مع زر لمسحها.
class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActivityProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              color: Color(0xFFB45309), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الفلاتر مفعلة ($count شرط)',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => provider.clearFilter(),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}
