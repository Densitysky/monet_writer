import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import 'package:monet_writer/models/chapter_history.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/services/database_service.dart';

/// 桌面端：时光机快照比对视窗
class DesktopHistoryDialog extends StatefulWidget {
  final WritingProvider provider;
  const DesktopHistoryDialog({super.key, required this.provider});

  @override
  State<DesktopHistoryDialog> createState() => _DesktopHistoryDialogState();
}

class _DesktopHistoryDialogState extends State<DesktopHistoryDialog> {
  List<ChapterHistory> _histories = [];
  ChapterHistory? _selectedHistory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    final chapterId = widget.provider.currentChapter?.id;
    if (chapterId == null) return;

    try {
      // 动态获取集合，防止 generated 命名差异
      final collection = DatabaseService().isar.collection<ChapterHistory>();
      // 假设模型中有 chapterId 字段 (根据你的 mixin 推断)
      final results = await collection.filter().chapterIdEqualTo(chapterId).findAll();

      if (mounted) {
        setState(() {
          // 倒序排列：最新的快照在最上面
          _histories = results.reversed.toList();
          if (_histories.isNotEmpty) {
            _selectedHistory = _histories.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('读取时光机失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _restoreSelected() async {
    if (_selectedHistory == null) return;

    // 调用你底层的时光机恢复逻辑
    await widget.provider.restoreHistory(_selectedHistory!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ 已成功恢复历史版本！')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
        side: isFlat ? BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
      ),
      child: SizedBox(
        width: 900,
        height: 600,
        child: Column(
          children: [
            // 顶部栏
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05)))),
              child: Row(
                children: [
                  Icon(CupertinoIcons.clock, color: primaryColor),
                  const SizedBox(width: 12),
                  Text('版本时光机 - ${widget.provider.currentChapter?.title ?? ""}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  const Spacer(),
                  IconButton(icon: Icon(CupertinoIcons.clear, color: currentTheme.textColor.withValues(alpha: 0.5)), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            // 核心双栏视图
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _histories.isEmpty
                  ? Center(child: Text('暂无历史快照\n系统每10分钟自动保存一次', textAlign: TextAlign.center, style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3))))
                  : Row(
                children: [
                  // 左侧列表
                  Container(
                    width: 250,
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05)))),
                    child: ListView.builder(
                      itemCount: _histories.length,
                      itemBuilder: (context, index) {
                        final history = _histories[index];
                        final isSelected = _selectedHistory?.id == history.id;
                        // 假设模型有 timestamp 或 createdAt，这里用备用渲染方式
                        final timeStr = "快照记录 #${_histories.length - index}";

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: primaryColor.withValues(alpha: 0.1),
                          title: Text(timeStr, style: TextStyle(color: isSelected ? primaryColor : currentTheme.textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                          subtitle: Text('${history.wordCount} 字', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12)),
                          onTap: () => setState(() => _selectedHistory = history),
                        );
                      },
                    ),
                  ),
                  // 右侧详情
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _selectedHistory?.content ?? '',
                              style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.8), fontSize: 15, height: 1.8),
                            ),
                          ),
                        ),
                        // 底部操作区
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05)))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('恢复后，当前编辑的内容将自动打底保存，防止丢失', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.4))),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: _restoreSelected,
                                icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
                                label: const Text('恢复此版本'),
                                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0))),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}