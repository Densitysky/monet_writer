import 'package:flutter/material.dart';
import 'package:monet_writer/utils/provider_select_ext.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;

  const MarkdownToolbar({super.key, required this.controller});

  void _insertMarkdown(String prefix, String suffix, {bool isLinePrefix = false}) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.baseOffset == -1 || selection.extentOffset == -1) {
      controller.text = '$text\n$prefix$suffix';
      controller.selection = TextSelection.collapsed(offset: controller.text.length - suffix.length);
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);

    if (isLinePrefix) {
      int lineStart = start;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }

      final newText = text.replaceRange(lineStart, lineStart, prefix);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: end + prefix.length),
      );
    } else {
      final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = context.selectCurrentTheme;
    final isPaper = context.selectIsPaper;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: currentTheme.textColor.withValues(alpha: 0.05), // 高级透明底色
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0), // 动态圆角
        // 【已修复】已彻底删除导致报错的 border 属性，在扁平风下保持纯净的无框色块即可
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(context, 'B', '加粗', () => _insertMarkdown('**', '**')),
          Container(width: 1, height: 20, color: currentTheme.textColor.withValues(alpha: 0.1)),
          _buildBtn(context, 'H1', '大标题', () => _insertMarkdown('# ', '', isLinePrefix: true)),
          Container(width: 1, height: 20, color: currentTheme.textColor.withValues(alpha: 0.1)),
          _buildBtn(context, 'H2', '小标题', () => _insertMarkdown('## ', '', isLinePrefix: true)),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, String label, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: BouncingWidget(
        onTap: onTap,
        scaleFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary, // 保持操作按钮的高亮属性
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

