import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/activity.dart';
import '../../../domain/entities/category.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';

/// صفحة البحث اللحظي داخل كل الأنشطة (أو داخل قسم محدد).
///
/// النتائج تُحدَّث مباشرة أثناء الكتابة عبر [ActivityProvider].
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.category});

  /// عند إرساله يُقيَّد البحث بهذا القسم (يُستخدم من صفحة القسم).
  final Category? category;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query =
        context.select<ActivityProvider, String>((p) => p.searchQuery);
    final allResults =
        context.select<ActivityProvider, List<Activity>>((p) => p.searchResults);

    // عند تصفح بحث داخل قسم، نقتصر النتائج عليه.
    final results = widget.category == null
        ? allResults
        : allResults.where((a) => a.category == widget.category!.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'البحث' : 'البحث في ${widget.category!.name}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (value) =>
                  context.read<ActivityProvider>().setSearchQuery(value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن نشاط، لعبة، مسابقة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          context.read<ActivityProvider>().setSearchQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${results.length} نتيجة',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: query.isEmpty
                        ? 'ابدأ البحث'
                        : 'لا توجد نتائج لـ "$query"',
                    message: query.isEmpty
                        ? 'اكتب اسم النشاط أو كلمة من وصفه.'
                        : 'جرّب كلمات أخرى أو أزل الفلاتر.',
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
