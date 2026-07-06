import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

import 'package:monet_writer/pages/desktop/writing/desktop_history_dialog.dart';
import 'package:monet_writer/widgets/editor/monet_rich_editor.dart';
import 'package:monet_writer/utils/text_format_util.dart';
import 'package:monet_writer/pages/writing/components/image_export_page.dart';

class DesktopEditorPanel extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(String selectedText)? onAiTap;

  const DesktopEditorPanel({
    super.key,
    required this.onBack,
    this.onAiTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isPaper = themeProvider.isPaperOrParchment;
    final currentTheme = userProvider.currentTheme;

    return Column(
      children: [
        _buildHeader(context, currentTheme, provider, isPaper),
        Expanded(
          child: provider.currentChapter == null
              ? _buildEmptyState(currentTheme)
              : _buildEditor(context, currentTheme, provider, isPaper),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WritingTheme theme, WritingProvider provider, bool isPaper) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(icon: Icon(CupertinoIcons.chevron_back, color: theme.textColor.withValues(alpha: 0.7)), onPressed: onBack, tooltip: '返回书架'),
          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.currentChapter?.title ?? '暂无章节', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor.withValues(alpha: 0.8))),
              if (provider.currentChapter != null)
                Text(provider.isSaving ? '保存中...' : (provider.isDirty ? '未保存' : '已自动保存 · ${provider.currentChapter!.wordCount} 字'), style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.5))),
            ],
          ),

          const Spacer(),

          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.ellipsis_circle, color: theme.textColor.withValues(alpha: 0.5), size: 20),
            tooltip: '工具',
            color: theme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isPaper ? 4.0 : 10.0),
              side: BorderSide(color: theme.textColor.withValues(alpha: 0.08)),
            ),
            onSelected: (value) => _handleToolAction(value, context, provider),
            itemBuilder: (_) => [
              _menuItem('智能排版并复制', CupertinoIcons.wand_stars, 'smartCopy'),
              _menuItem('一键自动排版', CupertinoIcons.text_aligncenter, 'autoFormat'),
              _menuItem('原文复制', CupertinoIcons.doc_on_clipboard, 'rawCopy'),
              const PopupMenuDivider(),
              _menuItem('导出本章 TXT', CupertinoIcons.doc_text, 'exportChapter'),
              _menuItem('导出全书 TXT', CupertinoIcons.book, 'exportBook'),
              _menuItem('生成长图', CupertinoIcons.photo, 'imageExport'),
            ],
          ),

          IconButton(
            icon: Icon(CupertinoIcons.clock, color: theme.textColor.withValues(alpha: 0.5), size: 20),
            onPressed: () {
              if (provider.currentChapter != null) {
                showDialog(context: context, builder: (_) => DesktopHistoryDialog(provider: provider));
              }
            },
            tooltip: '时光机快照',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WritingTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text, size: 64, color: theme.textColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('请在左侧选择或新建章节', style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, WritingTheme theme, WritingProvider provider, bool isPaper) {
    return ListView(
      controller: provider.scrollController,
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 60),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: provider.titleController,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: theme.textColor, letterSpacing: 1.2),
                    decoration: InputDecoration(hintText: '输入章节标题', hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.2)), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
                    onChanged: (_) => provider.onContentChanged(),
                  ),
                  const SizedBox(height: 30),

                  MonetRichEditor(
                    controller: provider.contentController,
                    focusNode: provider.editorFocusNode,
                    hintText: '从这里开始你的故事...',
                    onAiTap: onAiTap,
                  ),

                  const SizedBox(height: 500),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static PopupMenuItem<String> _menuItem(String label, IconData icon, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static void _handleToolAction(String value, BuildContext context, WritingProvider provider) {
    final scaffold = ScaffoldMessenger.of(context);

    switch (value) {
      case 'smartCopy':
        provider.smartCopyCurrentChapter().then((ok) {
          if (ok) scaffold.showSnackBar(const SnackBar(content: Text('✨ 智能排版完成，已复制到剪贴板'), behavior: SnackBarBehavior.floating));
        });
        break;

      case 'rawCopy':
        provider.rawCopyCurrentChapter().then((ok) {
          if (ok) scaffold.showSnackBar(const SnackBar(content: Text('📄 原文已无损复制到剪贴板'), behavior: SnackBarBehavior.floating));
        });
        break;

      case 'autoFormat':
        final tempController = TextEditingController(text: provider.contentController.text);
        tempController.selection = provider.contentController.selection;
        TextFormatUtil.autoFormat(tempController, () {
          provider.contentController.text = tempController.text;
          provider.contentController.selection = tempController.selection;
          provider.onContentChanged();
        });
        scaffold.showSnackBar(const SnackBar(content: Text('✅ 排版完成：已自动缩进并清理多余空行'), behavior: SnackBarBehavior.floating));
        break;

      case 'exportChapter':
        provider.exportCurrentChapterTxt().then((ok) {
          if (!ok) scaffold.showSnackBar(const SnackBar(content: Text('❌ 导出失败，请重试'), behavior: SnackBarBehavior.floating));
        });
        break;

      case 'exportBook':
        provider.exportWholeBookTxt().then((ok) {
          if (!ok) scaffold.showSnackBar(const SnackBar(content: Text('❌ 导出失败，请重试'), behavior: SnackBarBehavior.floating));
        });
        break;

      case 'imageExport':
        Navigator.push(context, CupertinoPageRoute(builder: (_) => ImageExportPage(provider: provider)));
        break;
    }
  }
}

