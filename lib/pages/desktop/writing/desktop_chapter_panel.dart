import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import 'package:monet_writer/models/book/chapter.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/database_service.dart';

class DesktopChapterPanel extends StatelessWidget {
  const DesktopChapterPanel({super.key});

  // --- 新建章节弹窗 ---
  void _showCreateChapterDialog(BuildContext context, WritingProvider provider, bool isPaper, WritingTheme theme) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
          side: isPaper ? BorderSide(color: theme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
        ),
        title: Text('新建章节', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: '输入章节名称...',
            hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3)),
            filled: true,
            fillColor: theme.textColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0), borderSide: BorderSide.none),
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              provider.createChapter(controller.text.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0))),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createChapter(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  // --- 【新增核心】章节右键悬浮菜单 ---
  void _showChapterContextMenu(BuildContext context, Offset position, Chapter chapter, WritingProvider provider, bool isPaper, WritingTheme theme) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: theme.backgroundColor,
      elevation: isPaper ? 2 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0),
        side: isPaper ? BorderSide(color: theme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(children: [Icon(CupertinoIcons.pencil, size: 18, color: theme.textColor), const SizedBox(width: 8), Text('重命名', style: TextStyle(color: theme.textColor))]),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(children: [Icon(CupertinoIcons.share, size: 18, color: theme.textColor), const SizedBox(width: 8), Text('导出本章 TXT', style: TextStyle(color: theme.textColor))]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('移至废纸篓', style: TextStyle(color: Colors.redAccent))]),
        ),
      ],
    );

    if (result == 'rename') {
      // 先选中该章，再利用底层的 titleController 重新保存
      await provider.selectChapter(chapter);
      if (!context.mounted) return;
      _showRenameChapterDialog(context, provider, isPaper, theme);
    } else if (result == 'export') {
      await provider.selectChapter(chapter);
      await provider.exportCurrentChapterTxt();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 导出请求已发送')));
    } else if (result == 'delete') {
      await provider.moveChapterToTrash(chapter);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ 已移至废纸篓')));
    }
  }

  // --- 重命名弹窗 ---
  void _showRenameChapterDialog(BuildContext context, WritingProvider provider, bool isPaper, WritingTheme theme) {
    final TextEditingController controller = TextEditingController(text: provider.currentChapter?.title ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0), side: isPaper ? BorderSide(color: theme.textColor.withValues(alpha: 0.1)) : BorderSide.none),
        title: Text('重命名章节', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(filled: true, fillColor: theme.textColor.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0), borderSide: BorderSide.none)),
          onSubmitted: (_) {
            provider.titleController.text = controller.text.trim();
            provider.saveCurrentChapter();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          FilledButton(
            onPressed: () {
              provider.titleController.text = controller.text.trim();
              provider.saveCurrentChapter();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // 【核心修改】：砍掉了恶心的返回箭头，换成了优雅的小书本图标，并调整了边距
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(CupertinoIcons.book, size: 18, color: currentTheme.textColor.withValues(alpha: 0.4)),
              const SizedBox(width: 10),
              Expanded(child: Text(provider.book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.textColor))),
            ],
          ),
        ),
        Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),
        Expanded(
          child: StreamBuilder<List<Chapter>>(
            stream: DatabaseService().isar.chapters.filter().bookIdEqualTo(provider.book.id).sortByOrderIndex().watch(fireImmediately: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));
              final chapterList = snapshot.data!;
              if (chapterList.isEmpty) return Center(child: Text('暂无章节\n点击下方按钮创建', textAlign: TextAlign.center, style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3), height: 1.5)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: chapterList.length,
                itemBuilder: (context, index) {
                  final chapter = chapterList[index];
                  final isSelected = provider.currentChapter?.id == chapter.id;

                  return _DesktopChapterTile(
                    chapter: chapter,
                    isSelected: isSelected,
                    isPaper: isPaper,
                    currentTheme: currentTheme,
                    primaryColor: primaryColor,
                    onTap: () => provider.selectChapter(chapter),
                    onSecondaryTapDown: (details) => _showChapterContextMenu(context, details.globalPosition, chapter, provider, isPaper, currentTheme),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border(top: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05), width: 1))),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _showCreateChapterDialog(context, provider, isPaper, currentTheme),
              icon: const Icon(CupertinoIcons.add, size: 16), label: const Text('新建章节', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: isPaper ? currentTheme.textColor.withValues(alpha: 0.05) : primaryColor.withValues(alpha: 0.1), foregroundColor: isPaper ? currentTheme.textColor.withValues(alpha: 0.8) : primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0))),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopChapterTile extends StatefulWidget {
  final Chapter chapter;
  final bool isSelected;
  final bool isPaper;
  final WritingTheme currentTheme;
  final Color primaryColor;
  final VoidCallback onTap;
  final void Function(TapDownDetails) onSecondaryTapDown;

  const _DesktopChapterTile({
    required this.chapter, required this.isSelected, required this.isPaper, required this.currentTheme, required this.primaryColor, required this.onTap, required this.onSecondaryTapDown,
  });

  @override
  State<_DesktopChapterTile> createState() => _DesktopChapterTileState();
}

class _DesktopChapterTileState extends State<_DesktopChapterTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.primaryColor;
    final inactiveColor = widget.currentTheme.textColor.withValues(alpha: 0.7);
    final textColor = widget.isSelected ? activeColor : inactiveColor;

    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = activeColor.withValues(alpha: widget.isPaper ? 0.08 : 0.12);
    } else if (_isHovered) backgroundColor = widget.currentTheme.textColor.withValues(alpha: 0.04);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.isPaper ? 8.0 : 12.0, vertical: 2.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, height: 40,
            decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(widget.isPaper ? 4.0 : 8.0)),
            child: Row(
              children: [
                if (widget.isPaper) AnimatedContainer(duration: const Duration(milliseconds: 200), width: 3, height: widget.isSelected ? 20 : 0, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: activeColor, borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)))) else const SizedBox(width: 12),
                Icon(widget.isSelected ? CupertinoIcons.doc_text_fill : CupertinoIcons.doc_text, size: 16, color: widget.isSelected ? activeColor : widget.currentTheme.textColor.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.chapter.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal, color: textColor))),
                if (widget.chapter.wordCount > 0) Padding(padding: const EdgeInsets.only(right: 12), child: Text('${widget.chapter.wordCount}', style: TextStyle(fontSize: 11, color: widget.currentTheme.textColor.withValues(alpha: widget.isSelected || _isHovered ? 0.5 : 0.3)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
