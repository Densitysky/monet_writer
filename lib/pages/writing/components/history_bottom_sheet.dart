import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入主题引擎
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/models/chapter_history.dart';
import 'package:monet_writer/services/database_service.dart';

class HistoryBottomSheet extends StatefulWidget {
  final WritingProvider provider;
  const HistoryBottomSheet({super.key, required this.provider});

  @override
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  List<ChapterHistory> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    try {
      if (widget.provider.currentChapter == null) return;
      final histories =
      await DatabaseService().getChapterHistories(widget.provider.currentChapter!.id);
      if (mounted) {
        setState(() {
          _histories = histories;
        });
      }
    } catch (e) {
      debugPrint('获取历史记录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取历史记录异常: $e', style: const TextStyle(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRestoreDialog(ChapterHistory history, bool isFlat) {
    final userProvider = context.read<UserProvider>();
    final theme = userProvider.currentTheme;
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(history.timestamp);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)), // 【动态圆角】
        backgroundColor: theme.backgroundColor,
        title: Text('恢复历史版本',
            style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确定要将本章恢复至 $timeStr 的版本吗？\n\n（系统会在恢复前自动为您当前的草稿再保存一次快照。）',
                style: TextStyle(color: theme.textColor.withValues(alpha: 0.8), height: 1.5),
              ),
              const SizedBox(height: 16),
              Text('内容预览：', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0), // 【动态圆角】
                  border: isFlat ? null : Border.all(color: theme.textColor.withValues(alpha: 0.1)), // 极简风不要边框
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    history.content,
                    style: TextStyle(color: theme.textColor.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.provider.restoreHistory(history);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已成功恢复至历史版本！')),
              );
            },
            child: const Text('确认恢复', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final difference = today.difference(targetDate).inDays;
    final timePart = DateFormat('HH:mm').format(timestamp);

    if (difference == 0) return '今日 $timePart';
    if (difference == 1) return '昨日 $timePart';
    if (difference == 2) return '前日 $timePart';
    return '${DateFormat('MM-dd').format(timestamp)} $timePart';
  }

  Widget _buildDiffSummaryWidget(String oldText, String newText, Color defaultColor) {
    if (oldText == newText) {
      return Text("(无内容变动)", style: TextStyle(color: defaultColor.withValues(alpha: 0.5), fontSize: 14));
    }

    int start = 0;
    int minLen = math.min(oldText.length, newText.length);
    while (start < minLen && oldText[start] == newText[start]) start++;

    int oldEnd = oldText.length - 1;
    int newEnd = newText.length - 1;
    while (oldEnd >= start && newEnd >= start && oldText[oldEnd] == newText[newEnd]) {
      oldEnd--;
      newEnd--;
    }

    String deleted = oldText.substring(start, oldEnd + 1).replaceAll('\n', ' ').trim();
    String added = newText.substring(start, newEnd + 1).replaceAll('\n', ' ').trim();

    if (deleted.length > 30) deleted = '${deleted.substring(0, 30)}...';
    if (added.length > 30) added = '${added.substring(0, 30)}...';

    List<InlineSpan> spans = [];

    if (deleted.isNotEmpty && added.isEmpty) {
      spans.add(const TextSpan(text: "删除：", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)));
      spans.add(TextSpan(text: deleted, style: TextStyle(color: defaultColor.withValues(alpha: 0.8))));
    } else if (deleted.isEmpty && added.isNotEmpty) {
      spans.add(const TextSpan(text: "新增：", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
      spans.add(TextSpan(text: added, style: TextStyle(color: defaultColor.withValues(alpha: 0.8))));
    } else {
      spans.add(const TextSpan(text: "修改：", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)));
      spans.add(TextSpan(text: "\"$deleted\" -> \"$added\"", style: TextStyle(color: defaultColor.withValues(alpha: 0.8))));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: TextStyle(fontSize: 14, height: 1.4, color: defaultColor), children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = userProvider.currentTheme;
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat; // 【动态判断】

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
              ],
            ),

          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('时光机 (历史快照)', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
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

          Expanded(
            child: _isLoading
                ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.textColor.withValues(alpha: 0.4)),
                )
            )
                : _histories.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.clock_fill, size: 60, color: theme.textColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('暂无历史记录\n(每 10 分钟或退出时自动保存)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), height: 1.5),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _histories.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.textColor.withValues(alpha: 0.05), indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final history = _histories[index];
                final timeStr = _formatRelativeTime(history.timestamp);
                final oldContent = index < _histories.length - 1 ? _histories[index + 1].content : "";
                final diffSummary = _buildDiffSummaryWidget(oldContent, history.content, theme.textColor);

                int diff = 0;
                if (index < _histories.length - 1) {
                  diff = history.wordCount - _histories[index + 1].wordCount;
                } else {
                  diff = history.wordCount;
                }
                final diffStr = diff > 0 ? '+$diff' : '$diff';
                final diffColor = diff > 0 ? Colors.green : (diff < 0 ? Colors.redAccent : Colors.grey);

                return InkWell(
                  onTap: () => _showRestoreDialog(history, isFlat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 2),
                          child: Icon(CupertinoIcons.clock, size: 20, color: theme.textColor.withValues(alpha: 0.4)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              diffSummary,
                              const SizedBox(height: 6),
                              Text('共 ${history.wordCount} 字', style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(timeStr, style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isFlat ? 4.0 : 6.0)), // 【动态圆角】
                              child: Text(diffStr, style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}