import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/models/character/character.dart';
import 'package:monet_writer/models/character/character_group.dart';
import 'package:monet_writer/pages/writing/character_profile_page.dart';
import 'package:monet_writer/pages/writing/components/character_card.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/utils/markdown_text_editing_controller.dart';
import 'package:monet_writer/pages/writing/components/markdown_toolbar.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  bool _isExtracting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingProvider>();
    final theme = Theme.of(context);
    final currentTheme = context.watch<UserProvider>().currentTheme;

    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('角色管理', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.5))),
              ),

              if (provider.book.characterGroups != null)
                ...List.generate(provider.book.characterGroups!.length, (gIndex) {
                  final group = provider.book.characterGroups![gIndex];
                  return FadeSlideEntrance(
                    delayMs: (gIndex > 10 ? 10 : gIndex) * 50,
                    child: _buildGroupItem(context, provider, group, gIndex, currentTheme, isFlat),
                  );
                }),

              if (provider.book.characters != null)
                ...List.generate(provider.book.characters!.length, (cIndex) {
                  final character = provider.book.characters![cIndex];
                  final baseLength = provider.book.characterGroups?.length ?? 0;
                  final totalIndex = baseLength + cIndex;

                  return FadeSlideEntrance(
                    delayMs: (totalIndex > 10 ? 10 : totalIndex) * 50,
                    child: _buildDraggableCharacterItem(
                      context,
                      provider,
                      character,
                      cIndex,
                      null,
                      isFlat,
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // 底部工具栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(top: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isExtracting ? null : () => _handleExtract(context, provider),
                  icon: _isExtracting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isExtracting ? '提取中...' : '提取角色'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              IconButton.outlined(
                onPressed: () => _showCreateGroupDialog(context, provider, isFlat),
                icon: Icon(Icons.create_new_folder_outlined, size: 20, color: currentTheme.textColor.withValues(alpha: 0.8)),
                tooltip: '新建组',
                style: IconButton.styleFrom(
                  side: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _showCharacterDialog(context, provider, isEdit: false, isFlat: isFlat),
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                tooltip: '新建角色',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleExtract(BuildContext context, WritingProvider provider) async {
    final aiProvider = context.read<AiProvider>();
    if (aiProvider.config.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在设置中配置 AI API Key')));
      return;
    }

    setState(() => _isExtracting = true);
    try {
      final count = await provider.extractCharactersFromContent(aiProvider.config);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 成功提取并添加了 $count 个角色'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提取失败: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Widget _buildGroupItem(BuildContext context, WritingProvider provider, CharacterGroup group, int groupIndex, WritingTheme currentTheme, bool isFlat) {
    final theme = Theme.of(context);
    return DragTarget<Map<String, int?>>(
      onWillAcceptWithDetails: (details) => details.data?['groupIndex'] != groupIndex,
      onAcceptWithDetails: (details) {
        final data = details.data;
        provider.moveCharacter(fromIndex: data['index']!, fromGroupIndex: data['groupIndex'], toGroupIndex: groupIndex);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('移动成功'), duration: Duration(milliseconds: 500)));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isHovering ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
            border: isHovering ? Border.all(color: theme.colorScheme.primary) : null,
          ),
          child: ExpansionTile(
            leading: Icon(Icons.folder_shared, color: theme.colorScheme.secondary),
            title: Text(group.title ?? '未命名分组', style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold)),
            iconColor: currentTheme.textColor,
            collapsedIconColor: currentTheme.textColor.withValues(alpha: 0.5),
            shape: const Border(),
            collapsedShape: const Border(),
            trailing: _buildMoreMenu(
              context,
              onEdit: () => _showRenameGroupDialog(context, provider, groupIndex, group.title ?? '', isFlat),
              onDelete: () => _confirmDeleteGroup(context, provider, groupIndex, group.safeCharacters.isNotEmpty, isFlat),
            ),
            children: List.generate(group.safeCharacters.length, (index) {
              final character = group.safeCharacters[index];
              return _buildDraggableCharacterItem(context, provider, character, index, groupIndex, isFlat);
            }),
          ),
        );
      },
    );
  }

  Widget _buildDraggableCharacterItem(BuildContext context, WritingProvider provider, Character character, int index, int? groupIndex, bool isFlat) {
    final dragData = {'index': index, 'groupIndex': groupIndex};

    final childWidget = CharacterCard(
      character: character,
      onTap: () {
        final currentWritingProvider = context.read<WritingProvider>();
        Navigator.push(
          context,
          MonetPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: currentWritingProvider,
              child: CharacterProfilePage(character: character, index: index, groupIndex: groupIndex),
            ),
          ),
        );
      },
      onEdit: () => _showCharacterDialog(context, provider, isEdit: true, character: character, index: index, groupIndex: groupIndex, isFlat: isFlat),
      onDelete: () => provider.deleteCharacter(index, groupIndex: groupIndex),
    );

    return LongPressDraggable<Map<String, int?>>(
      data: dragData,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              boxShadow: [
                if (!isFlat)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 15),
                  )
              ],
              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
              // 【核心修复：彻底删除了这里的 border，拥抱绝对的留白纯净】
            ),
            child: childWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: childWidget),
      child: childWidget,
    );
  }

  Widget _buildMoreMenu(BuildContext context, {required VoidCallback onEdit, required VoidCallback onDelete}) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('编辑')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  void _showCharacterDialog(BuildContext context, WritingProvider provider, {required bool isEdit, Character? character, int? index, int? groupIndex, required bool isFlat}) {
    showMonetDialog(
      context: context,
      builder: (_) => _CharacterEditDialog(
        isEdit: isEdit,
        originalCharacter: character,
        isFlat: isFlat,
        onSave: (name, desc, path) async {
          if (isEdit) {
            provider.updateCharacter(index!, groupIndex: groupIndex, newName: name, newDesc: desc, newAvatarPath: path);
          } else {
            await provider.createCharacter(name: name, desc: desc);
            if (path != null) {
              final characters = provider.book.characters;
              if (characters != null && characters.isNotEmpty) {
                provider.updateCharacter(characters.length - 1, groupIndex: null, newAvatarPath: path);
              }
            }
          }
        },
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WritingProvider provider, bool isFlat) {
    final controller = TextEditingController();
    showMonetDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('新建分组'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '例如：主角团',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)),
            )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createCharacterGroup(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenameGroupDialog(BuildContext context, WritingProvider provider, int index, String oldName, bool isFlat) {
    final controller = TextEditingController(text: oldName);
    showMonetDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('重命名分组'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameCharacterGroup(index, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, WritingProvider provider, int index, bool hasContent, bool isFlat) {
    if (!hasContent) {
      provider.deleteCharacterGroup(index);
      return;
    }
    showMonetDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('删除分组？'),
        content: const Text('删除分组将一并删除组内角色，是否继续？', style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
            onPressed: () {
              provider.deleteCharacterGroup(index);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _CharacterEditDialog extends StatefulWidget {
  final bool isEdit;
  final Character? originalCharacter;
  final Function(String name, String desc, String? path) onSave;
  final bool isFlat;

  const _CharacterEditDialog({required this.isEdit, this.originalCharacter, required this.onSave, required this.isFlat});

  @override
  State<_CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<_CharacterEditDialog> {
  late TextEditingController _nameCtrl;
  late MarkdownTextEditingController _descCtrl;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.originalCharacter?.name ?? '');
    _descCtrl = MarkdownTextEditingController(text: widget.originalCharacter?.description ?? '');
    _avatarPath = widget.originalCharacter?.avatarPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: '裁切头像', toolbarColor: Colors.deepPurple, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
          IOSUiSettings(title: '裁切头像', aspectRatioLockEnabled: true),
        ],
      );
      if (croppedFile != null) {
        setState(() => _avatarPath = croppedFile.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 20.0)),
      title: Text(widget.isEdit ? '编辑角色' : '新建角色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                  child: _avatarPath == null ? const Icon(Icons.add_a_photo, size: 30) : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 绘图引擎接入中...'))),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI 生成头像'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: '角色名称',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 12.0))
              ),
            ),
            const SizedBox(height: 16),

            MarkdownToolbar(controller: _descCtrl),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                  labelText: '详细简介/核心萌点',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 12.0)),
                  alignLabelWithHint: true
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 20.0))),
          onPressed: () {
            if (_nameCtrl.text.isNotEmpty) {
              widget.onSave(_nameCtrl.text, _descCtrl.text, _avatarPath);
              Navigator.pop(context);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}