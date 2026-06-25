import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/pages/writing/writing_page.dart';
import 'package:monet_writer/services/export_service.dart';
import 'package:monet_writer/pages/bookshelf/components/book_edit_dialog.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/widgets/monet_book_cover.dart';
import 'package:monet_writer/utils/color_utils.dart';

class HeroBookCard extends StatefulWidget {
  final Book book;
  const HeroBookCard({
    super.key,
    required this.book,
  });

  @override
  State<HeroBookCard> createState() => _HeroBookCardState();
}

class _HeroBookCardState extends State<HeroBookCard> {
  Color? _themeColor;

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  @override
  void didUpdateWidget(HeroBookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.coverPath != widget.book.coverPath) {
      _extractColor();
    }
  }

  Future<void> _extractColor() async {
    if (widget.book.coverPath != null && File(widget.book.coverPath!).existsSync()) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          FileImage(File(widget.book.coverPath!)),
          maximumColorCount: 10,
        );
        if (mounted) {
          setState(() {
            _themeColor = palette.dominantColor?.color;
          });
        }
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _themeColor ?? theme.colorScheme.primary;
    final bool hasCover = widget.book.coverPath != null && File(widget.book.coverPath!).existsSync();
    final overlayWhite = hasCover ? Colors.white : contrastTextColor(primaryColor);
    // 按钮使用相反极性：overlay 为浅色时按钮浅底深字，反之为深底浅字
    final isOverlayLight = overlayWhite.computeLuminance() > 0.5;
    final buttonBg = overlayWhite;
    final buttonFg = isOverlayLight ? Colors.black87 : Colors.white70;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 6,
      shadowColor: primaryColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WritingPage(
              book: widget.book,
              initialChapterIndex: -1,
            )),
          );
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: hasCover
                  ? Image.file(
                File(widget.book.coverPath!),
                fit: BoxFit.cover,
              )
                  : Container(color: theme.colorScheme.primaryContainer),
            ),
            if (hasCover)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (hasCover ? Colors.black.withValues(alpha: 0.6) : primaryColor.withValues(alpha: 0.8)),
                      (hasCover ? Colors.black.withValues(alpha: 0.8) : theme.colorScheme.surface),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: overlayWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history_edu, size: 14, color: overlayWhite),
                            const SizedBox(width: 4),
                            Text('最近阅读', style: TextStyle(color: overlayWhite, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward, size: 18, color: overlayWhite.withValues(alpha: 0.7)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'book_cover_${widget.book.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: MonetBookCover(book: widget.book, width: 80, height: 115, radius: 8),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: overlayWhite, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '上次更新：${DateFormat('MM-dd HH:mm').format(widget.book.updatedAt)}',
                              style: TextStyle(color: overlayWhite.withValues(alpha: 0.8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.book.wordCount} 字',
                              style: TextStyle(color: overlayWhite, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => WritingPage(
                                book: widget.book,
                                initialChapterIndex: -1,
                              )),
                            );
                          },
                          icon: const Icon(Icons.edit_note),
                          label: const Text('继续写作'),
                          style: FilledButton.styleFrom(
                            backgroundColor: buttonBg,
                            foregroundColor: buttonFg,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _showEditPanel(context),
                        icon: const Icon(Icons.more_horiz),
                        style: IconButton.styleFrom(
                          backgroundColor: overlayWhite.withValues(alpha: 0.2),
                          foregroundColor: overlayWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑书籍信息'),
              onTap: () { Navigator.pop(ctx); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => BookEditPanel(book: widget.book)); },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('导出为 TXT'),
              onTap: () { Navigator.pop(ctx); ExportService.exportToTxt(context, widget.book); },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Colors.green),
              title: const Text('导出为 EPUB'),
              onTap: () { Navigator.pop(ctx); ExportService.exportToEpub(context, widget.book); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除书籍', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _showDeleteConfirm(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除《${widget.book.title}》吗？\n书籍将移动到回收站。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final isar = DatabaseService().isar;
              await isar.writeTxn(() async {
                widget.book.isDeleted = true;
                await isar.books.put(widget.book);
              });
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
