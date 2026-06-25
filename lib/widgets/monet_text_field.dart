import 'package:flutter/material.dart';

class MonetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;

  // 改为可空 int，允许传 null 实现自适应高度
  final int? maxLines;
  final int minLines;

  final bool autoFocus;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  // 【新增】支持彻底的无边框/无底色模式，用于沉浸式写作或列表项
  final bool borderless;

  const MonetTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.maxLines = 1, // 默认为 1
    this.minLines = 1,
    this.autoFocus = false,
    this.keyboardType,
    this.onChanged,
    this.borderless = false, // 默认保留边框
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 智能判断：检测当前的主题引擎是否已经全局接管了输入框的样式 (比如我们的扁平风)
    final isThemeHandled = theme.inputDecorationTheme.border != null;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autoFocus,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: borderless ? null : label, // 无边框模式下通常隐藏 label，以 hint 为主
        hintText: hint ?? label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,

        // 【核心修改】
        // 1. 优先判断 borderless，如果为 true，彻底透明化
        // 2. 否则判断 isThemeHandled，自动适配全局的扁平/现代主题
        filled: borderless ? false : (isThemeHandled ? null : true),
        fillColor: borderless
            ? Colors.transparent
            : (isThemeHandled ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),

        border: borderless ? InputBorder.none : (isThemeHandled ? null : _buildModernBorder()),
        enabledBorder: borderless ? InputBorder.none : (isThemeHandled ? null : _buildModernBorder(color: Colors.transparent)),
        focusedBorder: borderless ? InputBorder.none : (isThemeHandled ? null : _buildModernBorder(color: theme.colorScheme.primary, width: 2)),
      ),
    );
  }

  // 保留你原本在 M3 现代风下的 12 像素圆角设定
  OutlineInputBorder _buildModernBorder({Color color = Colors.transparent, double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}