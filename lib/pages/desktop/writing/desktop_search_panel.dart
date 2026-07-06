import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

/// 桌面端：全局搜索与替换悬浮面板
class DesktopSearchPanel extends StatefulWidget {
  final WritingProvider provider;
  final VoidCallback onClose;

  const DesktopSearchPanel({super.key, required this.provider, required this.onClose});

  @override
  State<DesktopSearchPanel> createState() => _DesktopSearchPanelState();
}

class _DesktopSearchPanelState extends State<DesktopSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  SearchReport? _report;
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // 调用底层的搜索算法
    final report = await widget.provider.searchBook(query);
    if (mounted) {
      setState(() {
        _report = report;
        _hasSearched = true;
      });
    }
  }

  Future<void> _replaceCurrent() async {
    final query = _searchController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    await widget.provider.replaceInCurrentChapter(query, replaceText);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已完成本章替换')));
    _performSearch(); // 刷新结果
  }

  Future<void> _replaceAll() async {
    final query = _searchController.text;
    final replaceText = _replaceController.text;
    if (query.isEmpty) return;

    final count = await widget.provider.replaceInAllChapters(query, replaceText);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚀 替换完毕！全书共替换 $count 处。')));
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor,
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
        boxShadow: isPaper ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))],
        border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部栏
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                Icon(CupertinoIcons.search, size: 16, color: currentTheme.textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text('查找与替换', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: currentTheme.textColor)),
                const Spacer(),
                IconButton(icon: const Icon(CupertinoIcons.clear, size: 14), onPressed: widget.onClose, padding: EdgeInsets.zero, constraints: const BoxConstraints(), splashRadius: 16),
              ],
            ),
          ),
          Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

          // 输入区
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField('查找内容...', _searchController, currentTheme, isPaper, onSubmitted: (_) => _performSearch()),
                const SizedBox(height: 12),
                _buildTextField('替换为...', _replaceController, currentTheme, isPaper),
                const SizedBox(height: 16),

                // 按钮组
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.provider.isSearching ? null : _performSearch,
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0))),
                        child: widget.provider.isSearching
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('查找全部', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _replaceCurrent,
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0))),
                        child: const Text('本章替换', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _replaceAll,
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0))),
                        child: const Text('全局替换', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 结果展示区
          if (_hasSearched && _report != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: primaryColor.withValues(alpha: 0.05),
              child: Text('全书共找到 ${_report!.totalBookMatches} 处匹配 (影响 ${_report!.affectedChaptersCount} 章)', style: TextStyle(fontSize: 12, color: primaryColor)),
            ),
            if (_report!.chapterMatches.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _report!.chapterMatches.length,
                  itemBuilder: (context, index) {
                    final chapterId = _report!.chapterMatches.keys.elementAt(index);
                    final matches = _report!.chapterMatches[chapterId]!;
                    return ExpansionTile(
                      title: Text(matches.first.chapterTitle, style: TextStyle(fontSize: 13, color: currentTheme.textColor, fontWeight: FontWeight.bold)),
                      children: matches.map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: currentTheme.textColor.withValues(alpha: 0.02),
                        child: Text(m.previewContext, style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.8))),
                      )).toList(),
                    );
                  },
                ),
              )
          ] else if (_hasSearched) ...[
            Padding(padding: const EdgeInsets.all(16), child: Text('没有找到匹配项。', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.5)))),
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, WritingTheme theme, bool isPaper, {Function(String)? onSubmitted}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0), border: isPaper ? Border.all(color: theme.textColor.withValues(alpha: 0.1)) : null),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.textColor, fontSize: 13),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3), fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
