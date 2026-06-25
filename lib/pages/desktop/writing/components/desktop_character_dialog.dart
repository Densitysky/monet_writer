import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

import 'package:monet_writer/models/character/character.dart';
import 'package:monet_writer/models/character/character_event.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/ai_service.dart';

/// 桌面端：角色档案双栏大视窗 (沉浸式模态框)
class DesktopCharacterDialog extends StatefulWidget {
  final bool isEdit;
  final Character? character;
  final int? index;
  final int? groupIndex;

  const DesktopCharacterDialog({
    super.key,
    required this.isEdit,
    this.character,
    this.index,
    this.groupIndex,
  });

  @override
  State<DesktopCharacterDialog> createState() => _DesktopCharacterDialogState();
}

class _DesktopCharacterDialogState extends State<DesktopCharacterDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _tagCtrl;

  String? _avatarPath;
  List<String> _tags = [];
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _nameCtrl = TextEditingController(text: widget.character?.name ?? '');
    _descCtrl = TextEditingController(text: widget.character?.description ?? '');
    _bioCtrl = TextEditingController(text: widget.character?.bio ?? '');
    _tagCtrl = TextEditingController();

    _avatarPath = widget.character?.avatarPath;
    if (widget.character?.tags != null) {
      _tags = List.from(widget.character!.tags!);
    }

    _extractColor();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _bioCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  // 【核心修复】：纯桌面端选图 + 呼出原生裁剪弹窗
  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;

    // 呼出下方定义的桌面级裁剪弹窗
    final croppedPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CharacterCropDialog(imagePath: result.files.single.path!),
    );

    if (croppedPath != null && mounted) {
      setState(() => _avatarPath = croppedPath);
      _extractColor();
    }
  }

  Future<void> _extractColor() async {
    if (_avatarPath == null || !File(_avatarPath!).existsSync()) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(FileImage(File(_avatarPath!)));
      if (mounted) setState(() => _extractedColor = palette.dominantColor?.color ?? palette.vibrantColor?.color);
    } catch (_) {}
  }

  void _saveAndClose() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('角色名字不能为空')));
      return;
    }

    final provider = context.read<WritingProvider>();
    if (widget.isEdit) {
      await provider.updateCharacter(
        widget.index!,
        groupIndex: widget.groupIndex,
        newName: _nameCtrl.text,
        newDesc: _descCtrl.text,
        newBio: _bioCtrl.text,
        newAvatarPath: _avatarPath,
        newTags: _tags,
      );
    } else {
      await provider.createCharacter(
        name: _nameCtrl.text,
        desc: _descCtrl.text,
      );
      final newChars = provider.book.characters;
      if (newChars != null && newChars.isNotEmpty) {
        await provider.updateCharacter(
          newChars.length - 1,
          newBio: _bioCtrl.text,
          newAvatarPath: _avatarPath,
          newTags: _tags,
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _syncWithAi() {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写角色名字')));
      return;
    }

    if (!widget.isEdit || widget.index == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💡 这是一个新角色，请先点击右下角【保存修改】，然后再打开它进行 AI 提炼')));
      return;
    }

    final aiProvider = context.read<AiProvider>();
    final provider = context.read<WritingProvider>();

    provider.analyzeCharacterWithAi(aiProvider.config, _nameCtrl.text, index: widget.index!, groupIndex: widget.groupIndex);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚡ AI 正在后台阅读正文并提炼设定...')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final baseColor = _extractedColor ?? Theme.of(context).colorScheme.primary;
    final isAnalyzing = provider.isAnalyzing(_nameCtrl.text);

    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
        side: isFlat ? BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 900,
        height: 650,
        child: Row(
          children: [
            // 左侧：视觉身份区
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: isFlat ? currentTheme.textColor.withValues(alpha: 0.02) : baseColor.withValues(alpha: 0.1),
                border: isFlat ? Border(right: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: baseColor.withValues(alpha: 0.2),
                          border: isFlat ? Border.all(color: baseColor, width: 2) : Border.all(color: Colors.white, width: 4),
                          boxShadow: isFlat ? null : [BoxShadow(color: baseColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          image: (_avatarPath != null && File(_avatarPath!).existsSync())
                              ? DecorationImage(image: FileImage(File(_avatarPath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _avatarPath == null ? Icon(CupertinoIcons.camera, size: 40, color: baseColor) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      decoration: InputDecoration(hintText: '输入角色名', border: InputBorder.none, hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3))),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: isAnalyzing
                        ? CircularProgressIndicator(color: baseColor)
                        : FilledButton.tonalIcon(
                      onPressed: _syncWithAi,
                      icon: const Icon(CupertinoIcons.wand_rays, size: 16),
                      label: const Text('AI 提炼设定'),
                      style: FilledButton.styleFrom(
                        backgroundColor: baseColor.withValues(alpha: 0.15),
                        foregroundColor: baseColor,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)),
                      ),
                    ),
                  ),
                  if (widget.isEdit) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        provider.deleteCharacter(widget.index!, groupIndex: widget.groupIndex);
                        Navigator.pop(context);
                      },
                      icon: const Icon(CupertinoIcons.trash, size: 14, color: Colors.redAccent),
                      label: const Text('删除此角色', style: TextStyle(color: Colors.redAccent)),
                    ),
                    const SizedBox(height: 16),
                  ]
                ],
              ),
            ),

            // 右侧：数据编辑区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 54,
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05)))),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: baseColor,
                      labelColor: baseColor,
                      unselectedLabelColor: currentTheme.textColor.withValues(alpha: 0.5),
                      tabs: const [Tab(text: '基础资料与设定'), Tab(text: '经历时间轴')],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicTab(currentTheme, isFlat),
                        _buildEventTab(currentTheme, isFlat, baseColor),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.05)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: _saveAndClose,
                          style: FilledButton.styleFrom(
                            backgroundColor: baseColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)),
                          ),
                          child: const Text('保存修改', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildBasicTab(WritingTheme currentTheme, bool isFlat) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildDesktopInput(label: '一句话简介 (定位)', controller: _descCtrl, currentTheme: currentTheme, isFlat: isFlat, hint: '例如：深藏不露的扫地僧...'),
        const SizedBox(height: 24),
        _buildDesktopInput(label: '生平总括 / 核心性格', controller: _bioCtrl, currentTheme: currentTheme, isFlat: isFlat, maxLines: 6, hint: '在此书写角色的出身、核心动机等...'),
        const SizedBox(height: 24),

        Text('角色标签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _tagCtrl,
                  style: TextStyle(color: currentTheme.textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '输入新标签，回车添加',
                    hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)),
                    filled: true, fillColor: currentTheme.textColor.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() { _tags.add(val.trim()); _tagCtrl.clear(); });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag, style: TextStyle(fontSize: 12, color: currentTheme.textColor)),
            backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
            deleteIconColor: currentTheme.textColor.withValues(alpha: 0.5),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)),
            onDeleted: () => setState(() => _tags.remove(tag)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildEventTab(WritingTheme currentTheme, bool isFlat, Color baseColor) {
    final events = widget.character?.lifeEvents ?? [];
    return Column(
      children: [
        Expanded(
          child: events.isEmpty
              ? Center(child: Text('暂无经历事件，请在移动端补充或让 AI 提炼', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.4))))
              : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.textColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0),
                  border: isFlat ? Border.all(color: currentTheme.textColor.withValues(alpha: 0.08)) : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(event.timePoint ?? '未知', style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title ?? '未命名事件', style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                          const SizedBox(height: 4),
                          Text(event.content ?? '', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6))),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopInput({required String label, required TextEditingController controller, required WritingTheme currentTheme, required bool isFlat, int maxLines = 1, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: currentTheme.textColor, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)),
            filled: true,
            fillColor: currentTheme.textColor.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

/// ==========================================
/// 新增：桌面级角色头像独立裁剪弹窗
/// ==========================================
class _CharacterCropDialog extends StatefulWidget {
  final String imagePath;
  const _CharacterCropDialog({required this.imagePath});

  @override
  State<_CharacterCropDialog> createState() => _CharacterCropDialogState();
}

class _CharacterCropDialogState extends State<_CharacterCropDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _saveCroppedImage() async {
    setState(() => _isSaving = true);
    try {
      // 捕捉缩放+平移后的可见区域
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0); // 3倍超清采样
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final String fileName = 'char_avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      debugPrint('角色头像裁剪失败: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;

    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('调整角色头像', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 8),
            Text('支持鼠标拖拽平移、滚轮缩放', style: TextStyle(fontSize: 13, color: theme.textColor.withValues(alpha: 0.5))),
            const SizedBox(height: 32),

            // 核心取景框
            Container(
              width: 260,
              height: 260,
              clipBehavior: Clip.antiAlias, // 严格切出正圆
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
              ),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: theme.backgroundColor,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _saveCroppedImage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('保存头像', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}