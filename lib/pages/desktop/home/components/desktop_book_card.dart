import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/services/export_service.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/widgets/monet_book_cover.dart';

import 'package:monet_writer/pages/desktop/home/components/desktop_book_dialog.dart';
import 'package:monet_writer/pages/desktop/writing/desktop_writing_page.dart';

class DesktopBookCard extends StatefulWidget {
  final Book book;

  const DesktopBookCard({super.key, required this.book});

  @override
  State<DesktopBookCard> createState() => _DesktopBookCardState();
}

class _DesktopBookCardState extends State<DesktopBookCard> {
  bool _isHovering = false;

  void _openBook() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DesktopWritingPage(book: widget.book),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      items: [
        const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.edit_note, size: 18), SizedBox(width: 8), Text('继续写作')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.settings_outlined, size: 18), SizedBox(width: 8), Text('书籍设置')])),
        const PopupMenuItem(value: 'export_txt', child: Row(children: [Icon(Icons.text_snippet_outlined, size: 18), SizedBox(width: 8), Text('导出为 TXT')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('移入废纸篓', style: TextStyle(color: Colors.red))])),
      ],
    ).then((value) {
      if (value == 'open') _openBook();
      if (value == 'edit') showDialog(context: context, builder: (_) => DesktopBookDialog(book: widget.book));
      if (value == 'export_txt') ExportService.exportToTxt(context, widget.book);
      if (value == 'delete') _showDeleteConfirm();
    });
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移入废纸篓'),
        content: Text('确定要将《${widget.book.title}》移入废纸篓吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final isar = DatabaseService().isar;
              await isar.writeTxn(() async {
                widget.book.isDeleted = true;
                await isar.books.put(widget.book);
              });
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;

    // 角标颜色 (模拟作家助手：连载中为蓝色，已完结/私密为深灰色)
    final statusColor = widget.book.status == 0 ? Colors.blue.shade600 : Colors.grey.shade800;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openBook,
        // 右键依然可以呼出菜单
        onSecondaryTapDown: (details) => _showContextMenu(context, details),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== 1. 封面区域 ==================
            AspectRatio(
              aspectRatio: 3 / 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, _isHovering ? -4 : 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isFlat ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isHovering ? 0.15 : 0.08),
                      blurRadius: _isHovering ? 16 : 8,
                      offset: _isHovering ? const Offset(0, 8) : const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return MonetBookCover(
                              book: widget.book,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              radius: 6
                          );
                        },
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6)
                          ),
                        ),
                        child: Text(
                            widget.book.status == 0 ? '连载中' : '已完结',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),

                    if (_isHovering)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ================== 2. 极简文字区域 ==================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                      widget.book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor, height: 1.3)
                  ),
                ),

                // 【核心修改】：移除 AnimatedOpacity 始终显示，并绑定左键点击
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (details) => _showContextMenu(context, details),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.only(left: 6.0, bottom: 6.0), // 提供更大的点击热区
                      child: Icon(Icons.more_horiz, size: 16, color: currentTheme.textColor.withValues(alpha: 0.5)),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 4),

            // 字数统计
            Text(
                '${widget.book.wordCount}字',
                style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.5))
            ),
          ],
        ),
      ),
    );
  }
}