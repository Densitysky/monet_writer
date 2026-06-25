import 'package:flutter/material.dart';

/// 离开编辑器前的保存确认对话框
///
/// 提供三种操作：
/// - 保存并退出：触发 [onSaveAndExit]
/// - 不保存直接退出：触发 [onDiscardAndExit]
/// - 取消：关闭对话框
class SaveBeforeExitDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onSaveAndExit;
  final VoidCallback onDiscardAndExit;

  const SaveBeforeExitDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.onSaveAndExit,
    required this.onDiscardAndExit,
  });

  /// 便捷方法：通过 showDialog 弹出
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onSaveAndExit,
    required VoidCallback onDiscardAndExit,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SaveBeforeExitDialog(
        title: title,
        subtitle: subtitle,
        onSaveAndExit: onSaveAndExit,
        onDiscardAndExit: onDiscardAndExit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)))
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('取消', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        TextButton(
          onPressed: () {
            onDiscardAndExit();
            Navigator.pop(context, true);
          },
          child: Text('不保存', style: TextStyle(color: colorScheme.error)),
        ),
        FilledButton(
          onPressed: () {
            onSaveAndExit();
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('保存并退出'),
        ),
      ],
    );
  }
}
