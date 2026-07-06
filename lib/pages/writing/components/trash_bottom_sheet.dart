import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入主题引擎
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/models/book/trashed_chapter.dart';

class TrashBottomSheet extends StatefulWidget {
  final WritingProvider provider;
  const TrashBottomSheet({super.key, required this.provider});

  @override
  State<TrashBottomSheet> createState() => _TrashBottomSheetState();
}

class _TrashBottomSheetState extends State<TrashBottomSheet> {
  List<TrashedChapter> _trashedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final list = await widget.provider.getTrashedChapters();
    if (mounted) {
      setState(() {
        _trashedList = list;
        _isLoading = false;
      });
    }
  }

  void _showHardDeleteConfirm(TrashedChapter chapter, bool isPaper) {
    final theme = context.read<UserProvider>().currentTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 16.0)), // 【动态圆角】
        backgroundColor: theme.backgroundColor,
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('彻底删除', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          '警告：确定要彻底销毁《${chapter.title}》吗？\n此操作不可逆转，数据将永久从设备中抹除。',
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
              await widget.provider.hardDeleteTrashedChapter(chapter);
              _loadTrash();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已彻底粉碎该章节')));
              }
            },
            child: const Text('彻底粉碎', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;
    final isPaper = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.paper; // 【动态判断】

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(isPaper ? 0.0 : 20.0)), // 【动态抹平顶部】
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPaper) // 【纸感风隐藏拖拽条】
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
                child: Text('章节废纸篓', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
              Positioned(
                right: 16,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0), // 【动态圆角】
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0)),
                    child: Icon(CupertinoIcons.xmark, size: 20, color: theme.textColor.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(theme.textColor.withValues(alpha: 0.4))))
                : _trashedList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.trash, size: 60, color: theme.textColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('废纸篓是空的\n所有安全删除的章节会暂时存放于此',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), height: 1.5),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _trashedList.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.textColor.withValues(alpha: 0.05), indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final chapter = _trashedList[index];
                final timeStr = DateFormat('MM-dd HH:mm').format(chapter.deletedAt);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(CupertinoIcons.doc_text, size: 24, color: theme.textColor.withValues(alpha: 0.3)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textColor.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '删于 $timeStr  |  ${chapter.wordCount} 字',
                              style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.blueAccent.withValues(alpha: 0.8), size: 22),
                            tooltip: '恢复',
                            onPressed: () async {
                              await widget.provider.restoreChapterFromTrash(chapter);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已成功恢复《${chapter.title}》')));
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.trash, color: Colors.redAccent.withValues(alpha: 0.8), size: 22),
                            tooltip: '彻底粉碎',
                            onPressed: () => _showHardDeleteConfirm(chapter, isPaper),
                          ),
                        ],
                      )
                    ],
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

