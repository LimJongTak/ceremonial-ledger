import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/custom_category.dart';
import '../../models/event_model.dart';
import '../../providers/custom_category_provider.dart';
import '../common/app_theme.dart';

class CategorySettingsScreen extends ConsumerWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customs = ref.watch(customCategoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('카테고리 관리',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, ref, null, null),
        icon: const Icon(Icons.add),
        label: const Text('카테고리 추가'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 기본 카테고리
          _SectionHeader(
            title: '기본 카테고리',
            subtitle: '앱 기본 제공 항목 (편집 불가)',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: CeremonyType.values.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Column(
                  children: [
                    if (i > 0)
                      const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                            child: Text(c.emoji,
                                style: const TextStyle(fontSize: 18))),
                      ),
                      title: Text(c.label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('기본',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // 커스텀 카테고리
          _SectionHeader(
            title: '커스텀 카테고리',
            subtitle: '직접 추가한 항목 (탭해서 편집)',
          ),
          const SizedBox(height: 8),

          if (customs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Text('✨',
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text('아직 커스텀 카테고리가 없어요',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('아래 버튼으로 추가해보세요',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: customs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, indent: 56),
                      ListTile(
                        onTap: () => _showEditDialog(context, ref, i, cat),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                              child: Text(cat.emoji,
                                  style: const TextStyle(fontSize: 18))),
                        ),
                        title: Text(cat.label,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('커스텀',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  _confirmDelete(context, ref, i, cat),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.expense),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, int? index, CustomCategory? cat) {
    final emojiCtrl = TextEditingController(text: cat?.emoji ?? '');
    final labelCtrl = TextEditingController(text: cat?.label ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? '카테고리 추가' : '카테고리 편집',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: InputDecoration(
                labelText: '이모지',
                hintText: '예: 🎵',
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: '이름',
                hintText: '예: 음악회',
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final emoji = emojiCtrl.text.trim();
              final label = labelCtrl.text.trim();
              if (emoji.isEmpty || label.isEmpty) return;

              final newCat = CustomCategory(emoji: emoji, label: label);
              if (index == null) {
                ref.read(customCategoryProvider.notifier).add(newCat);
              } else {
                ref.read(customCategoryProvider.notifier).update(index, newCat);
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: Text(index == null ? '추가' : '저장'),
          ),
        ],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, int index, CustomCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(
            '"${cat.emoji} ${cat.label}" 카테고리를 삭제할까요?\n기존 내역의 표시는 유지됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(customCategoryProvider.notifier).remove(index);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
}
