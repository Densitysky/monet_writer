import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/widgets/editor/monet_editor_controller.dart';

class MonetRichEditor extends StatelessWidget {
  final MonetEditorController controller;
  final FocusNode focusNode;
  final String hintText;
  final EdgeInsetsGeometry padding;

  // 【核心升级】：新增滚动相关的控制权暴露
  final ScrollController? scrollController;
  final bool scrollable;
  final bool expands;

  const MonetRichEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = '从这里开始你的故事...',
    this.padding = EdgeInsets.zero,
    this.scrollController,
    this.scrollable = false, // 桌面端默认 false，跟随外部 ListView
    this.expands = false,    // 桌面端默认 false
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = userProvider.currentTheme;

    final defaultTextStyle = TextStyle(
      fontSize: userProvider.fontSize,
      height: userProvider.lineHeight,
      fontFamily: userProvider.effectiveFontFamily,
      color: theme.textColor.withValues(alpha: 0.9),
      letterSpacing: 0.6,
    );

    return QuillEditor(
      controller: controller.quillController,
      focusNode: focusNode,
      scrollController: scrollController ?? ScrollController(),
      config: QuillEditorConfig(
        autoFocus: false,
        expands: expands,       // 【接收外部指令】：是否撑满高度
        scrollable: scrollable, // 【接收外部指令】：是否内部自驱滚动
        padding: padding,
        placeholder: hintText,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            defaultTextStyle,
            const HorizontalSpacing(0, 0),
            VerticalSpacing(0, userProvider.paragraphSpacing),
            const VerticalSpacing(0, 0),
            null,
          ),
          placeHolder: DefaultTextBlockStyle(
            defaultTextStyle.copyWith(color: theme.textColor.withValues(alpha: 0.3)),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
}