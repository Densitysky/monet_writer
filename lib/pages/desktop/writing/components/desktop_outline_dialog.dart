import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

enum OutlineNodeType { core, plotNode, tabNode }

/// 桌面端：大纲与节点深度编辑视窗
class DesktopOutlineDialog extends StatefulWidget {
  final OutlineNodeType nodeType;
  final bool isEdit;

  // 核心设定专用
  final String? initialDescription;
  final String? initialOutline;

  // 独立节点 (Plot Node) 或 分组节点 (Tab Node) 专用
  final int? targetIndex;
  final int? tabIndex;
  final String? initialTitle;
  final String? initialContent;

  const DesktopOutlineDialog({
    super.key,
    required this.nodeType,
    required this.isEdit,
    this.initialDescription,
    this.initialOutline,
    this.targetIndex,
    this.tabIndex,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<DesktopOutlineDialog> createState() => _DesktopOutlineDialogState();
}

class _DesktopOutlineDialogState extends State<DesktopOutlineDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.nodeType == OutlineNodeType.core) {
      _titleCtrl = TextEditingController(text: widget.initialDescription ?? '');
      _contentCtrl = TextEditingController(text: widget.initialOutline ?? '');
    } else {
      _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
      _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    final provider = context.read<WritingProvider>();

    if (widget.nodeType == OutlineNodeType.core) {
      await provider.updateCoreOutline(_titleCtrl.text, _contentCtrl.text);
    }
    else if (widget.nodeType == OutlineNodeType.plotNode) {
      if (_titleCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('节点标题不能为空')));
        return;
      }
      if (widget.isEdit && widget.targetIndex != null) {
        await provider.updatePlotNode(widget.targetIndex!, _titleCtrl.text, _contentCtrl.text);
      } else {
        await provider.addPlotNode(_titleCtrl.text, _contentCtrl.text);
      }
    }
    else if (widget.nodeType == OutlineNodeType.tabNode) {
      if (_titleCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('节点标题不能为空')));
        return;
      }
      if (widget.isEdit && widget.tabIndex != null && widget.targetIndex != null) {
        await provider.updateNodeInTab(widget.tabIndex!, widget.targetIndex!, _titleCtrl.text, _contentCtrl.text);
      } else if (!widget.isEdit && widget.tabIndex != null) {
        await provider.addNodeToTab(widget.tabIndex!, _titleCtrl.text, _contentCtrl.text);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNode() async {
    final provider = context.read<WritingProvider>();
    if (widget.nodeType == OutlineNodeType.plotNode && widget.targetIndex != null) {
      await provider.deletePlotNode(widget.targetIndex!);
    } else if (widget.nodeType == OutlineNodeType.tabNode && widget.tabIndex != null && widget.targetIndex != null) {
      await provider.deleteNodeInTab(widget.tabIndex!, widget.targetIndex!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final isPaper = themeProvider.isPaperOrParchment;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final String dialogTitle = widget.nodeType == OutlineNodeType.core
        ? '核心设定与世界观'
        : (widget.isEdit ? '编辑剧情节点' : '新建剧情节点');

    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 16.0),
        side: isPaper ? BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1)) : BorderSide.none,
      ),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(widget.nodeType == OutlineNodeType.core ? CupertinoIcons.globe : CupertinoIcons.doc_text, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(dialogTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                const Spacer(),
                if (widget.isEdit && widget.nodeType != OutlineNodeType.core)
                  IconButton(
                    onPressed: _deleteNode,
                    icon: const Icon(CupertinoIcons.trash),
                    color: Colors.redAccent,
                    tooltip: '删除此节点',
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Text(widget.nodeType == OutlineNodeType.core ? '一句话核心梗概 (Logline)' : '节点标题', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true, fillColor: currentTheme.textColor.withValues(alpha: 0.05),
                hintText: widget.nodeType == OutlineNodeType.core ? '例如：一个废柴少年逆袭拯救世界的故事...' : '输入节点名称',
                hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Text(widget.nodeType == OutlineNodeType.core ? '详细世界观与主线大纲' : '节点详细剧情', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.7))),
                const Spacer(),
                if (widget.nodeType != OutlineNodeType.core)
                  TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ AI 扩写大纲功能筹备中'))),
                    icon: const Icon(CupertinoIcons.wand_rays, size: 14),
                    label: const Text('AI 扩写细纲', style: TextStyle(fontSize: 12)),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: currentTheme.textColor, fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  filled: true, fillColor: currentTheme.textColor.withValues(alpha: 0.05),
                  hintText: '在此记录详细设定或剧情走向...\n(支持换行与段落梳理)',
                  hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _saveAndClose,
                  icon: const Icon(CupertinoIcons.check_mark, size: 16),
                  label: const Text('保存内容', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0))),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
