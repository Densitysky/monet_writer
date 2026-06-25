import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/pages/writing/components/search_replace_sheet.dart';
import 'package:monet_writer/pages/writing/components/history_bottom_sheet.dart';
import 'package:monet_writer/pages/writing/components/image_export_page.dart';

class MoreActionsSheet extends StatelessWidget {
  final WritingProvider provider;
  const MoreActionsSheet({super.key, required this.provider});

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap, ThemeData theme, UserProvider userProvider, bool isFlat) {
    final currentTheme = userProvider.currentTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isFlat ? 8.0 : 25.0), // 动态形状
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: currentTheme.textColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;
    final theme = userProvider.currentTheme;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 24.0)), // 【动态圆角】
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: theme.textColor.withValues(alpha: 0.05))),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFlat) // 极简风下不要这个拖拽横条
                  Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                      ]
                  ),
                SizedBox(height: isFlat ? 24 : 16),
                Text('更多功能', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildActionItem(context, CupertinoIcons.wand_stars, '智能排版\n并复制', Colors.purpleAccent, () async {
                        Navigator.pop(context);
                        final success = await provider.smartCopyCurrentChapter();
                        if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ 智能排版完成，已复制到剪贴板！')));
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.doc_on_clipboard, '原文复制', Colors.blueAccent, () async {
                        Navigator.pop(context);
                        final success = await provider.rawCopyCurrentChapter();
                        if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📄 原文已无损复制到剪贴板！')));
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.doc_text, '导出本章\n(TXT)', Colors.orangeAccent, () async {
                        Navigator.pop(context);
                        await provider.exportCurrentChapterTxt();
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.book, '导出全书\n(TXT)', Colors.redAccent, () async {
                        Navigator.pop(context);
                        await provider.exportWholeBookTxt();
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.search, '查找替换', Colors.green, () {
                        Navigator.pop(context);
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => SearchReplaceBottomSheet(provider: provider));
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.clock, '时光机', Colors.teal, () {
                        Navigator.pop(context);
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => HistoryBottomSheet(provider: provider));
                      }, Theme.of(context), userProvider, isFlat),

                      _buildActionItem(context, CupertinoIcons.photo, '生成长图', Colors.pinkAccent, () {
                        Navigator.pop(context);
                        Navigator.push(context, CupertinoPageRoute(builder: (context) => ImageExportPage(provider: provider)));
                      }, Theme.of(context), userProvider, isFlat),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}