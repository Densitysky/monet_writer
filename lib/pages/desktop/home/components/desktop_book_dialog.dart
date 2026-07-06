import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

// 【核心引入】：全局通用桌面端裁剪弹窗！
import 'package:monet_writer/pages/desktop/components/desktop_crop_dialog.dart';

class DesktopBookDialog extends StatefulWidget {
  final Book? book;

  const DesktopBookDialog({super.key, this.book});

  @override
  State<DesktopBookDialog> createState() => _DesktopBookDialogState();
}

class _DesktopBookDialogState extends State<DesktopBookDialog> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();

  String? _coverPath;
  int _status = 0; // 0: 连载中, 1: 已完结

  bool _isHoveringCover = false; // 控制封面的悬停遮罩状态

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.authorName ?? '';
      _descController.text = widget.book!.description ?? '';
      _coverPath = widget.book!.coverPath;
      _status = widget.book!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // 呼出全局 3:4 原生裁剪弹窗
  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;

    final croppedPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DesktopCropDialog(
        imagePath: result.files.single.path!,
        title: '调整书籍封面',
        boxWidth: 240.0,       // 3:4 比例的宽
        boxHeight: 320.0,      // 3:4 比例的高
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    if (croppedPath != null && mounted) {
      setState(() => _coverPath = croppedPath);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入书名')));
      return;
    }

    final author = _authorController.text.trim().isEmpty ? '佚名' : _authorController.text.trim();
    final desc = _descController.text.trim();

    String? finalCoverPath = _coverPath;
    if (_coverPath != widget.book?.coverPath && _coverPath != null) {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedImage = await File(_coverPath!).copy('${directory.path}/cover_$timestamp.jpg');
      finalCoverPath = savedImage.path;
    }

    final isar = DatabaseService().isar;
    if (isEditing) {
      await isar.writeTxn(() async {
        final book = widget.book!;
        book.title = title;
        book.authorName = author;
        book.description = desc;
        book.coverPath = finalCoverPath;
        book.status = _status;
        book.updatedAt = DateTime.now();
        await isar.books.put(book);
      });
    } else {
      final newBook = Book()
        ..title = title
        ..authorName = author
        ..description = desc
        ..coverPath = finalCoverPath
        ..status = _status
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.books.put(newBook);
      });
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final currentTheme = userProvider.currentTheme;

    // 【核心获取】：提取 ThemeProvider 中配置的 30% 结构灰底色
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Dialog(
      // 【全局纯净】：整个弹窗统一使用 60% 主背景色 (纯白/深黑)
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPaper ? 12.0 : 16.0),
        side: isPaper ? BorderSide(color: currentTheme.textColor.withValues(alpha: 0.08)) : BorderSide.none,
      ),
      child: SizedBox(
        width: 800,
        height: 560,
        child: Row(
          children: [
            // ================== 左侧：Apple Music 级封面展示区 ==================
            SizedBox(
              width: 280,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringCover = true),
                    onExit: (_) => setState(() => _isHoveringCover = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pickCover,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 180,
                        height: 240, // 严格锁定 3:4 比例
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(isPaper ? 6.0 : 12.0),
                          border: isPaper ? Border.all(color: currentTheme.textColor.withValues(alpha: 0.06)) : null,
                          boxShadow: isPaper ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 12))],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 封面底图
                            if (_coverPath != null && File(_coverPath!).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(isPaper ? 6.0 : 12.0),
                                child: Image.file(File(_coverPath!), fit: BoxFit.cover),
                              )
                            else
                              Center(child: Icon(CupertinoIcons.plus, size: 32, color: currentTheme.textColor.withValues(alpha: 0.2))),

                            // 【交互魔法】：悬停时平滑浮现的磨砂遮罩与相机图标
                            AnimatedOpacity(
                              opacity: _isHoveringCover ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(isPaper ? 6.0 : 12.0),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 28),
                                      SizedBox(height: 8),
                                      Text('更换封面', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 【克制分割】：一条极淡的 1px 垂直分割线
            VerticalDivider(width: 1, thickness: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

            // ================== 右侧：极致对齐的无边框表单区 ==================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? '编辑书籍信息' : '创建新作品', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: 1.2)),
                    const SizedBox(height: 32),

                    // 1. 书名 (100% 宽度)
                    _buildInputField(label: '书名', controller: _titleController, theme: currentTheme, autoFocus: !isEditing),
                    const SizedBox(height: 24),

                    // 2. 作者与连载状态 (各占 50%，绝对水平对齐)
                    Row(
                      children: [
                        Expanded(child: _buildInputField(label: '作者', controller: _authorController, theme: currentTheme)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStatusToggle(currentTheme, isPaper, surfaceColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. 简介 (充满剩余空间)
                    Expanded(
                      child: _buildInputField(label: '简介', controller: _descController, theme: currentTheme, maxLines: null, minLines: 5),
                    ),
                    const SizedBox(height: 24),

                    // ================== 底部操作区 ==================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(foregroundColor: currentTheme.textColor.withValues(alpha: 0.6)),
                          child: const Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 6.0 : 8.0)),
                          ),
                          child: const Text('保存书籍', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 专属表单组件：标签外置，内部无边框填充
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required WritingTheme theme,
    int? maxLines = 1,
    int? minLines,
    bool autoFocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        SizedBox(
          // 强制单行文本框高度为绝对 44px，保证与旁边的状态组件完美对齐
          height: maxLines == 1 ? 44 : null,
          child: TextField(
            controller: controller,
            autofocus: autoFocus,
            maxLines: maxLines,
            minLines: minLines,
            textAlignVertical: maxLines == 1 ? TextAlignVertical.center : TextAlignVertical.top,
            style: TextStyle(fontSize: 14, color: theme.textColor, height: 1.3),
            decoration: InputDecoration(
              hintText: '请输入$label',
              hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3), fontSize: 13),
              // 利用你在 ThemeProvider 中定好的 inputDecorationTheme，仅微调 Padding
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines == 1 ? 0 : 12),
            ),
          ),
        ),
      ],
    );
  }

  /// iOS 级连载状态滑动分段器 (Segmented Control)
  Widget _buildStatusToggle(WritingTheme theme, bool isPaper, Color surfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('连载状态', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        Container(
          height: 44, // 绝对锁定 44px，与输入框天衣无缝地平齐
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(isPaper ? 6.0 : 8.0),
            border: isPaper ? Border.all(color: theme.textColor.withValues(alpha: 0.05)) : null,
          ),
          child: Row(
            children: [
              Expanded(child: _buildSegmentBtn(0, '连载中', theme, isPaper)),
              Expanded(child: _buildSegmentBtn(1, '已完结', theme, isPaper)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentBtn(int value, String text, WritingTheme theme, bool isPaper) {
    final isSelected = _status == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.backgroundColor : Colors.transparent, // 选中时变成纯净的背景色色块
            borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0),
            boxShadow: (isSelected && !isPaper) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
            border: (isSelected && isPaper) ? Border.all(color: theme.textColor.withValues(alpha: 0.05)) : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? theme.textColor : theme.textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
