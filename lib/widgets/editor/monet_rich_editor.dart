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
  final ScrollController? scrollController;
  final bool scrollable;
  final bool expands;
  final void Function(String selectedText)? onAiTap;

  const MonetRichEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = '从这里开始你的故事...',
    this.padding = EdgeInsets.zero,
    this.scrollController,
    this.scrollable = false,
    this.expands = false,
    this.onAiTap,
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
        expands: expands,
        scrollable: scrollable,
        padding: padding,
        placeholder: hintText,
        contextMenuBuilder: (context, state) => _buildContextMenu(context, state, onAiTap),
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

  static Widget _buildContextMenu(
    BuildContext context,
    QuillRawEditorState state,
    void Function(String selectedText)? onAiTap,
  ) {
    final sel = state.textEditingValue.selection;
    final hasSel = sel.isValid && !sel.isCollapsed;

    final items = <ContextMenuButtonItem>[];

    if (hasSel) {
      items.add(ContextMenuButtonItem(
        label: 'AI 润色',
        onPressed: () {
          onAiTap?.call(sel.textInside(state.textEditingValue.text));
        },
      ));
    }

    items.addAll(state.contextMenuButtonItems);

    return TextFieldTapRegion(
      child: AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: items,
        anchors: state.contextMenuAnchors,
      ),
    );
  }
}
