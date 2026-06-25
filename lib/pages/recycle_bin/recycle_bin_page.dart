import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/widgets/monet_book_cover.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Book>>(
        stream: DatabaseService().watchDeletedBooks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final books = snapshot.data!;

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 80, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    '回收站是空的',
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return _DeletedBookItem(book: book);
            },
          );
        },
      ),
    );
  }
}

class _DeletedBookItem extends StatelessWidget {
  final Book book;

  const _DeletedBookItem({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 封面 (变灰以示删除)
          Opacity(
            opacity: 0.6,
            child: MonetBookCover(
              coverPath: book.coverPath,
              title: book.title,
              width: 50,
              height: 70,
              radius: 6,
            ),
          ),
          const SizedBox(width: 16),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '删除时间: ${dateFormat.format(book.updatedAt)}', // 这里暂时用 updatedAt 近似代替
                  style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.wordCount} 字',
                  style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: () => _handleRestore(context),
                icon: const Icon(Icons.restore),
                tooltip: '恢复',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  foregroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _handleDeleteForever(context),
                icon: const Icon(Icons.delete_forever),
                tooltip: '彻底删除',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRestore(BuildContext context) async {
    final ok = await DatabaseService().restoreBook(book.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '书籍已恢复到书架' : '恢复失败，请重试'),
    ));
  }

  void _handleDeleteForever(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('彻底删除'),
        content: const Text('此操作将永久删除该书及其所有章节，且无法撤销！\n\n确定要继续吗？', style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
}
