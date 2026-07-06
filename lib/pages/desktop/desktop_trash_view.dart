import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/widgets/theme/app_card.dart';

/// 桌面端：书籍回收站面板 (100% 对标安卓端 recycle_bin_page.dart)
class DesktopTrashView extends StatelessWidget {
  const DesktopTrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final currentTheme = userProvider.currentTheme;
    final bgColor = (isPaper || isNeumorphic) ? Theme.of(context).scaffoldBackgroundColor : currentTheme.backgroundColor;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: bgColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 顶部 Header
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 40, bottom: 24),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.trash, size: 28, color: currentTheme.textColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Text('回收站', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: currentTheme.textColor, letterSpacing: 1.2)),
                    const SizedBox(width: 12),
                    Text('(仅存放被删除的作品)', style: TextStyle(fontSize: 14, color: currentTheme.textColor.withValues(alpha: 0.5))),
                  ],
                ),
              ),

              // 2. 列表区 (使用流监听，自动刷新)
              Expanded(
                child: StreamBuilder<List<Book>>(
                  // 直接对接底层的被删书籍流
                  stream: DatabaseService().watchDeletedBooks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('加载出错: ${snapshot.error}', style: TextStyle(color: currentTheme.textColor)));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: primaryColor));
                    }

                    final books = snapshot.data!;

                    if (books.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.trash, size: 64, color: currentTheme.textColor.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text('回收站是空的', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.4), fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _DesktopDeletedBookItem(
                          book: book,
                          isPaper: isPaper,
                          currentTheme: currentTheme,
                          primaryColor: primaryColor,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDeletedBookItem extends StatelessWidget {
  final Book book;
  final bool isPaper;
  final WritingTheme currentTheme;
  final Color primaryColor;

  const _DesktopDeletedBookItem({
    required this.book,
    required this.isPaper,
    required this.currentTheme,
    required this.primaryColor,
  });

  // 恢复书籍
  void _handleRestore(BuildContext context) async {
    final ok = await DatabaseService().restoreBook(book.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '✅ 书籍已恢复到书架' : '恢复失败，请重试'),
    ));
  }

  // 彻底粉碎书籍
  void _handleDeleteForever(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
          side: isPaper ? BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
        ),
        title: Text('彻底删除', style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold)),
        content: Text('此操作将永久删除《${book.title}》及其所有章节，且无法撤销！\n\n确定要继续吗？', style: const TextStyle(color: Colors.redAccent, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await DatabaseService().deleteBookPermanently(book.id);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok ? '已彻底删除' : '删除失败，请重试'),
              ));
            },
            child: const Text('彻底粉碎'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final isNeumorphic = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.neumorphic;

    Widget cardContent = Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 桌面端简约封面 (变灰以示删除)
            Opacity(
              opacity: 0.6,
              child: Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isPaper ? 2.0 : 6.0),
                ),
                child: Center(
                  child: Text(
                    book.title.isNotEmpty ? book.title[0].toUpperCase() : '无',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 信息区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(CupertinoIcons.time, size: 12, color: currentTheme.textColor.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        '删除于 ${dateFormat.format(book.updatedAt)}',
                        style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(CupertinoIcons.doc_text, size: 12, color: currentTheme.textColor.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        '${book.wordCount} 字',
                        style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 操作按钮区
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _handleRestore(context),
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14),
                  label: const Text('还原'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0))
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleDeleteForever(context),
                  icon: const Icon(CupertinoIcons.trash),
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  tooltip: '彻底删除',
                )
              ],
            ),
          ],
        ),
      );

    if (isNeumorphic) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard(padding: EdgeInsets.zero, child: cardContent),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPaper ? Colors.transparent : currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
        border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: cardContent,
    );
  }
}
