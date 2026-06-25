import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

import 'package:monet_writer/pages/desktop/writing/desktop_history_dialog.dart';
import 'package:monet_writer/widgets/editor/monet_rich_editor.dart';

class DesktopEditorPanel extends StatelessWidget {
  final VoidCallback onBack;

  const DesktopEditorPanel({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;

    return Column(
      children: [
        _buildHeader(context, currentTheme, provider, isFlat),
        Expanded(
          child: provider.currentChapter == null
              ? _buildEmptyState(currentTheme)
              : _buildEditor(context, currentTheme, provider, isFlat),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WritingTheme theme, WritingProvider provider, bool isFlat) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.textColor.withValues(alpha: 0.05), width: 1))),
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

  Widget _buildEditor(BuildContext context, WritingTheme theme, WritingProvider provider, bool isFlat) {
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

                  // 【接管替换】去掉了错误的 onChanged 参数
                  MonetRichEditor(
                    controller: provider.contentController,
                    focusNode: provider.editorFocusNode,
                    hintText: '从这里开始你的故事...',
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
}