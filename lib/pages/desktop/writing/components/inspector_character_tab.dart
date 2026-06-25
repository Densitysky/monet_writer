import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/character/character.dart';
import 'package:monet_writer/models/character/character_group.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/pages/desktop/writing/components/desktop_character_dialog.dart';
import 'package:monet_writer/pages/desktop/writing/components/desktop_ai_task_manager.dart';

class InspectorCharacterTab extends StatefulWidget {
  final WritingTheme currentTheme;
  final bool isFlat;
  final Color primaryColor;

  const InspectorCharacterTab({
    super.key,
    required this.currentTheme,
    required this.isFlat,
    required this.primaryColor,
  });

  @override
  State<InspectorCharacterTab> createState() => _InspectorCharacterTabState();
}

class _InspectorCharacterTabState extends State<InspectorCharacterTab> {

  Future<void> _handleExtract(BuildContext context, WritingProvider provider) async {
    final aiProvider = context.read<AiProvider>();
    if (aiProvider.config.apiKey?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在全局设置中配置 AI API Key')));
      return;
    }

    if (DesktopAiTaskManager.instance.isWorking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 已有 AI 任务在后台运行中')));
      return;
    }

    DesktopAiTaskManager.instance.startTask('✨ AI 正在后台搜寻角色...');
    try {
      final count = await provider.extractCharactersFromContent(aiProvider.config);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 成功在后台提取了 $count 个角色')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提取失败: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    } finally {
      DesktopAiTaskManager.instance.stopTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingProvider>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('出场角色', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.currentTheme.textColor.withValues(alpha: 0.5))),
              ),

              // 1. 分组角色
              if (provider.book.characterGroups != null)
                ...List.generate(provider.book.characterGroups!.length, (gIndex) {
                  final group = provider.book.characterGroups![gIndex];
                  return _buildGroupItem(context, provider, group, gIndex);
                }),

              // 2. 未分组角色
              if (provider.book.characters != null)
                ...List.generate(provider.book.characters!.length, (cIndex) {
                  final character = provider.book.characters![cIndex];
                  return _buildDraggableCharacterItem(context, provider, character, cIndex, null);
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // 底部工具栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: widget.currentTheme.textColor.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                    listenable: DesktopAiTaskManager.instance,
                    builder: (context, _) {
                      final isExtracting = DesktopAiTaskManager.instance.isWorking;
                      return FilledButton.tonalIcon(
                        onPressed: isExtracting ? null : () => _handleExtract(context, provider),
                        icon: isExtracting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(CupertinoIcons.wand_rays, size: 14),
                        label: Text(isExtracting ? '提取中...' : 'AI 提取角色', style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0)),
                        ),
                      );
                    }
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  // 【核心修复：手动抓取 Provider 并传递给弹窗路由】
                  final currentProvider = context.read<WritingProvider>();
                  showDialog(
                    context: context,
                    builder: (_) => ChangeNotifierProvider<WritingProvider>.value(
                      value: currentProvider,
                      child: const DesktopCharacterDialog(isEdit: false),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.add, size: 16),
                tooltip: '手动新建角色',
                style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItem(BuildContext context, WritingProvider provider, CharacterGroup group, int groupIndex) {
    return DragTarget<Map<String, int?>>(
      onWillAcceptWithDetails: (details) => details.data['groupIndex'] != groupIndex,
      onAcceptWithDetails: (details) {
        provider.moveCharacter(fromIndex: details.data['index']!, fromGroupIndex: details.data['groupIndex'], toGroupIndex: groupIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isHovering ? widget.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0),
            border: isHovering ? Border.all(color: widget.primaryColor) : null,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(CupertinoIcons.folder, size: 18, color: widget.currentTheme.textColor.withValues(alpha: 0.7)),
              title: Text(group.title ?? '未命名分组', style: TextStyle(color: widget.currentTheme.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
              iconColor: widget.currentTheme.textColor,
              collapsedIconColor: widget.currentTheme.textColor.withValues(alpha: 0.5),
              childrenPadding: const EdgeInsets.only(left: 12),
              children: List.generate(group.safeCharacters.length, (index) {
                final character = group.safeCharacters[index];
                return _buildDraggableCharacterItem(context, provider, character, index, groupIndex);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableCharacterItem(BuildContext context, WritingProvider provider, Character character, int index, int? groupIndex) {
    final dragData = {'index': index, 'groupIndex': groupIndex};

    final childWidget = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isFlat ? Colors.transparent : widget.currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0),
        border: Border.all(color: widget.currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
          backgroundImage: (character.avatarPath != null && File(character.avatarPath!).existsSync()) ? FileImage(File(character.avatarPath!)) : null,
          child: character.avatarPath == null ? Text(character.name?.isNotEmpty == true ? character.name![0] : '?', style: TextStyle(color: widget.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)) : null,
        ),
        title: Text(character.name ?? '未知', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.currentTheme.textColor)),
        subtitle: Text(character.description ?? '暂无设定', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: widget.currentTheme.textColor.withValues(alpha: 0.5))),
        trailing: Icon(CupertinoIcons.right_chevron, size: 12, color: widget.currentTheme.textColor.withValues(alpha: 0.3)),
        onTap: () {
          // 【核心修复：手动抓取 Provider 并传递给弹窗路由】
          final currentProvider = context.read<WritingProvider>();
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.6),
            builder: (_) => ChangeNotifierProvider<WritingProvider>.value(
              value: currentProvider,
              child: DesktopCharacterDialog(isEdit: true, character: character, index: index, groupIndex: groupIndex),
            ),
          );
        },
      ),
    );

    return LongPressDraggable<Map<String, int?>>(
      data: dragData,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 260, child: Opacity(opacity: 0.8, child: childWidget))),
      childWhenDragging: Opacity(opacity: 0.3, child: childWidget),
      child: childWidget,
    );
  }
}