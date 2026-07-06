import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/pages/writing/writing_page.dart';
import 'package:monet_writer/services/export_service.dart';
import 'package:monet_writer/pages/bookshelf/components/book_edit_dialog.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/widgets/monet_book_cover.dart';
import 'package:monet_writer/widgets/theme/app_card.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final cardContent = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonetBookCover(book: book, width: 60, height: 80),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.wordCount} 字  •  ${dateFormat.format(book.updatedAt)}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description?.isNotEmpty == true ? book.description! : '暂无简介',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') _showEditDialog(context);
              if (value == 'export') _showExportDialog(context);
              if (value == 'delete') _showDeleteDialog(context);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('编辑信息')),
              const PopupMenuItem<String>(value: 'export', child: Text('导出')),
              const PopupMenuItem<String>(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );

    if (isNeumorphic) {
      return AppCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WritingPage(
              book: book,
              initialChapterIndex: -1,
            )),
          );
        },
        child: cardContent,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WritingPage(
              book: book,
              initialChapterIndex: -1,
            )),
          );
        },
        child: cardContent,
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookEditPanel(book: book),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('导出为 TXT'),
              onTap: () { Navigator.pop(ctx); ExportService.exportToTxt(context, book); },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Colors.green),
              title: const Text('导出为 EPUB'),
              onTap: () { Navigator.pop(ctx); ExportService.exportToEpub(context, book); },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除《${book.title}》吗？\n书籍将移动到回收站。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final isar = DatabaseService().isar;
              await isar.writeTxn(() async {
                book.isDeleted = true;
                await isar.books.put(book);
              });
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
