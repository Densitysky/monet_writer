import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:monet_writer/models/book/chapter.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入主题引擎
import 'package:monet_writer/pages/writing/components/trash_bottom_sheet.dart';

import 'package:monet_writer/utils/monet_animations.dart';

class WritingDrawer extends StatelessWidget {
  const WritingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WritingProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentTheme = userProvider.currentTheme;

    // 【核心】动态获取视觉风格
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;
    final double radius = isFlat ? 4.0 : 24.0; // 极简风小圆角，现代风大圆角

    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = currentTheme.backgroundColor.computeLuminance() < 0.5;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: EdgeInsets.only(top: topPadding + 10, bottom: 40, left: 10, right: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius), // 【动态圆角】
          boxShadow: [
            if (!isFlat) // 【极简风去阴影】
              BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(5, 5)
              )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), // 【动态圆角】
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: currentTheme.backgroundColor.withValues(alpha: 0.85),
                border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.05), width: 1),
              ),
              child: FutureBuilder<List<Chapter>>(
                future: DatabaseService().isar.chapters.filter().bookIdEqualTo(provider.book.id).sortByOrderIndex().findAll(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final chapters = snapshot.data!;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: currentTheme.textColor.withValues(alpha: 0.03),
                          border: Border(bottom: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(provider.book.title.isNotEmpty ? provider.book.title[0] : '无', style: TextStyle(color: theme.colorScheme.onPrimary))
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      provider.book.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor)
                                  ),
                                  Text(
                                      '共 ${chapters.length} 章',
                                      style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.6), fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: chapters.length,
                          itemBuilder: (ctx, index) {
                            final chapter = chapters[index];
                            final isSelected = provider.currentChapter?.id == chapter.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              // 【动态圆角】选中态的背景也做适配
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)),
                              title: Text(
                                  chapter.title,
                                  style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? theme.colorScheme.primary : currentTheme.textColor
                                  )
                              ),
                              subtitle: Text(
                                  '${chapter.wordCount} 字',
                                  style: TextStyle(fontSize: 10, color: currentTheme.textColor.withValues(alpha: 0.5))
                              ),
                              onTap: () { provider.selectChapter(chapter); Navigator.pop(context); },
                              trailing: IconButton(
                                icon: Icon(CupertinoIcons.trash, size: 18, color: currentTheme.textColor.withValues(alpha: 0.3)),
                                onPressed: () => _showDeleteConfirmDialog(context, provider, chapter, isFlat),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _showCreateDialog(context, provider, isFlat),
                                icon: const Icon(CupertinoIcons.add, size: 18),
                                label: const Text('新建章节'),
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0))), // 【动态圆角】
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48, width: 48,
                              decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)), // 【动态圆角】
                              child: IconButton(
                                icon: Icon(CupertinoIcons.trash, color: theme.colorScheme.error, size: 20),
                                tooltip: '废纸篓',
                                onPressed: () {
                                  Navigator.pop(context);
                                  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => TrashBottomSheet(provider: provider));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WritingProvider provider, bool isFlat) async {
    final count = await DatabaseService().isar.chapters.filter().bookIdEqualTo(provider.book.id).count();
    final defaultTitle = '第${count + 1}章';
    final controller = TextEditingController(text: defaultTitle);

    if (!context.mounted) return;

    await showMonetDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)), // 【动态圆角】
        title: const Text('新建章节'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '章节标题',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)), // 【动态圆角】
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))), // 【动态圆角】
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                provider.createChapter(controller.text);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WritingProvider provider, Chapter chapter, bool isFlat) {
    showMonetDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)), // 【动态圆角】
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orangeAccent, size: 24),
            SizedBox(width: 8),
            Text('移入废纸篓'),
          ],
        ),
        content: Text('确定要将《${chapter.title}》移入废纸篓吗？\n\n(您随时可以在底部废纸篓中将其恢复)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))), // 【动态圆角】
            onPressed: () {
              Navigator.pop(ctx);
              provider.moveChapterToTrash(chapter);
            },
            child: const Text('移入废纸篓', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}