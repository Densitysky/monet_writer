import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入主题引擎
import 'package:monet_writer/providers/writing_provider.dart';

class SearchReplaceBottomSheet extends StatefulWidget {
  final WritingProvider provider;
  const SearchReplaceBottomSheet({super.key, required this.provider});

  @override
  State<SearchReplaceBottomSheet> createState() => _SearchReplaceBottomSheetState();
}

class _SearchReplaceBottomSheetState extends State<SearchReplaceBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();

  SearchReport? _report;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _report = null);
      return;
    }

    setState(() => _isSearching = true);
    final report = await widget.provider.searchBook(query);
    if (mounted) {
      setState(() {
        _report = report;
        _isSearching = false;
      });
    }
  }

  void _showChapterReplaceConfirm(bool isFlat) {
    if (_report == null || _report!.currentChapterMatches == 0) return;
    final replaceText = _replaceController.text;
    final theme = context.read<UserProvider>().currentTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)), // 【动态圆角】
        backgroundColor: theme.backgroundColor,
        title: Text('本章替换确认', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        content: Text(
          '确认将本章中的 "${_report!.query}" 全部替换为 "$replaceText" 吗？\n\n本次操作将修改：${_report!.currentChapterMatches} 处',
          style: TextStyle(color: theme.textColor.withValues(alpha: 0.8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.provider.replaceInCurrentChapter(_report!.query, replaceText);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已替换本章 ${_report!.currentChapterMatches} 处')));
                _performSearch();
              }
            },
            child: const Text('确认替换', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGlobalReplaceConfirm(bool isFlat) {
    if (_report == null || _report!.totalBookMatches == 0) return;
    final replaceText = _replaceController.text;
    final theme = context.read<UserProvider>().currentTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)), // 【动态圆角】
        backgroundColor: theme.backgroundColor,
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('全局替换确认', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: theme.textColor.withValues(alpha: 0.8), height: 1.6, fontSize: 15),
            children: [
              const TextSpan(text: '即将把全书所有的 '),
              TextSpan(text: '"${_report!.query}"', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
              const TextSpan(text: ' 替换为 '),
              TextSpan(text: '"$replaceText"', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
              const TextSpan(text: '。\n\n'),
              const TextSpan(text: '📊 影响范围：\n', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '• 涉及章节：${_report!.affectedChaptersCount} 章\n'),
              TextSpan(text: '• 替换总数：${_report!.totalBookMatches} 处\n\n'),
              const TextSpan(text: '🛡️ 安全机制：\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const TextSpan(text: '系统将在执行前，自动为受影响的章节分别创建一份“时光机”历史快照，随时可撤销恢复。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await widget.provider.replaceInAllChapters(_report!.query, replaceText);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 成功全局替换 $count 处内容！')));
                _performSearch();
              }
            },
            child: Text('全局替换 (${_report!.totalBookMatches})', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = userProvider.currentTheme;
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat; // 【动态判断】
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 20.0)), // 【动态抹平顶部】
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFlat) // 【极简风隐藏拖拽条】
            Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                  ),
                ]
            ),

          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('全局搜索与替换', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
              Positioned(
                right: 16,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0), // 【动态圆角】
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                    child: Icon(CupertinoIcons.xmark, size: 20, color: theme.textColor.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: '查找内容...',
                    hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
                    prefixIcon: Icon(CupertinoIcons.search, color: theme.textColor.withValues(alpha: 0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(CupertinoIcons.arrow_right, color: theme.textColor),
                      onPressed: _performSearch,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), borderSide: BorderSide.none), // 【动态圆角】
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _replaceController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: '替换为... (选填)',
                    hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
                    prefixIcon: Icon(CupertinoIcons.arrow_swap, color: theme.textColor.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), borderSide: BorderSide.none), // 【动态圆角】
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                if (_report != null && !_isSearching) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '匹配：本章 ${_report!.currentChapterMatches} 处 | 全书 ${_report!.totalBookMatches} 处',
                          style: TextStyle(color: theme.textColor.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        children: [
                          if (_report!.currentChapterMatches > 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                                foregroundColor: Colors.blueAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)), // 【动态圆角】
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => _showChapterReplaceConfirm(isFlat),
                              child: const Text('本章替换'),
                            ),
                          const SizedBox(width: 8),
                          if (_report!.totalBookMatches > 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)), // 【动态圆角】
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => _showGlobalReplaceConfirm(isFlat),
                              child: const Text('全局替换', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      )
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),

          Expanded(
            child: _isSearching
                ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.textColor.withValues(alpha: 0.4)),
                )
            )
                : _report == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.search, size: 60, color: theme.textColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('输入关键字开始全书搜索\n支持精准的上下文匹配和一键替换',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), height: 1.5)),
                ],
              ),
            )
                : _report!.totalBookMatches == 0
                ? Center(child: Text('没有找到匹配的内容', style: TextStyle(color: theme.textColor.withValues(alpha: 0.5))))
                : ListView.builder(
              itemCount: _report!.chapterMatches.length,
              itemBuilder: (context, index) {
                final chapterId = _report!.chapterMatches.keys.elementAt(index);
                final items = _report!.chapterMatches[chapterId]!;
                final chapterTitle = items.first.chapterTitle;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      color: theme.textColor.withValues(alpha: 0.03),
                      width: double.infinity,
                      child: Text(
                        chapterTitle,
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ...items.map((item) {
                      final parts = item.previewContext.split(_report!.query);
                      List<InlineSpan> spans = [];
                      for (int i = 0; i < parts.length; i++) {
                        spans.add(TextSpan(text: parts[i]));
                        if (i < parts.length - 1) {
                          spans.add(TextSpan(
                            text: _report!.query,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ));
                        }
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        leading: Icon(CupertinoIcons.quote_bubble, size: 16, color: theme.textColor.withValues(alpha: 0.3)),
                        title: RichText(
                          text: TextSpan(
                            style: TextStyle(color: theme.textColor.withValues(alpha: 0.8), fontSize: 14, height: 1.4),
                            children: spans,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}