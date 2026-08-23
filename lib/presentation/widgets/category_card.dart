import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_resolver.dart';
import '../../domain/entities/category.dart';
import '../pages/category/category_page.dart';

/// بطاقة قسم بتصميم حيوي: شريط لوني علوي + أيقونة كبيرة + تدرج خفيف.
///
/// كل قسم له لون مميز يجعل البطاقات متميزة بصريًا.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.count});

  final Category category;
  final int count;

  static String _countLabel(int n) {
    if (n == 1) return 'نشاط واحد';
    if (n == 2) return 'نشاطان';
    return '$n نشاطًا';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryPage(category: category),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الشريط الملوّن العلوي ──
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.cardRadius),
                  ),
                ),
              ),
              // ── المحتوى ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الأيقونة + العنوان
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                color.withValues(alpha: isDark ? 0.25 : 0.15),
                                color.withValues(alpha: isDark ? 0.12 : 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            IconResolver.resolve(category.icon),
                            size: 24,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              height: 1.3,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // عدد الأنشطة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _countLabel(count),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
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
