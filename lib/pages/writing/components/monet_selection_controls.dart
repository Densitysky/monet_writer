import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/utils/provider_select_ext.dart';

/// 自定义文本选择控制器
class MonetSelectionControls extends MaterialTextSelectionControls {
  final WritingProvider provider;
  final VoidCallback onAiInputTriggered;

  MonetSelectionControls({
    required this.provider,
    required this.onAiInputTriggered,
  });

  @override
  Widget buildToolbar(
      BuildContext context,
      Rect globalEditableRegion,
      double textLineHeight,
      Offset selectionMidpoint,
      List<TextSelectionPoint> endpoints,
      TextSelectionDelegate delegate,
      ValueListenable<ClipboardStatus>? clipboardStatus,
      Offset? lastSecondaryTapDownPosition,
      ) {
    return _MonetToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      provider: provider,
      onAiInputTriggered: onAiInputTriggered,
      // ignore: deprecated_member_use
      handleCut: (delegate) => handleCut(delegate),
      // ignore: deprecated_member_use
      handleCopy: (delegate) => handleCopy(delegate),
      // ignore: deprecated_member_use
      handlePaste: (delegate) => handlePaste(delegate),
      // ignore: deprecated_member_use
      handleSelectAll: (delegate) => handleSelectAll(delegate),
    );
  }
}

class _MonetToolbar extends StatelessWidget {
  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;
  final TextSelectionDelegate delegate;
  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final WritingProvider provider;
  final VoidCallback onAiInputTriggered;
  final Function(TextSelectionDelegate) handleCut;
  final Function(TextSelectionDelegate) handleCopy;
  final Function(TextSelectionDelegate) handlePaste;
  final Function(TextSelectionDelegate) handleSelectAll;

  const _MonetToolbar({
    required this.globalEditableRegion,
    required this.textLineHeight,
    required this.selectionMidpoint,
    required this.endpoints,
    required this.delegate,
    this.clipboardStatus,
    required this.provider,
    required this.onAiInputTriggered,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
  });

  void _onSelectParagraph() {
    // 【修复 2：选段后气泡不消失】
    // 删除了原本这里的 delegate.hideToolbar();
    // 让系统在选中段落后，自动更新气泡的位置并保持浮现
    provider.selectCurrentParagraph();
    // 将视图滚动到新选区的末尾，确保用户能看到完整段落
    delegate.bringIntoView(provider.contentController.selection.extent);
  }

  void _onAiClick() {
    delegate.hideToolbar(); // 只有在呼出底部 AI 输入框时，才隐藏此气泡
    onAiInputTriggered();
  }

  @override
  Widget build(BuildContext context) {
    const double toolbarHeight = 44.0;
    final Offset anchor = Offset(
      selectionMidpoint.dx,
      (selectionMidpoint.dy - textLineHeight - toolbarHeight).clamp(20.0, double.infinity),
    );

    final currentTheme = context.selectCurrentTheme;
    final isFlat = context.selectIsFlat;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 气泡底色与文字颜色
    final tooltipBgColor = currentTheme.textColor.withValues(alpha: 0.95);
    final tooltipTextColor = currentTheme.backgroundColor;
    final tooltipIconColor = currentTheme.backgroundColor.withValues(alpha: 0.8);

    // 【修复 1：智能计算 AI 按钮的颜色】
    // 如果气泡背景是暗色，使用明亮的紫色 (PurpleAccent) 保证对比度
    // 如果气泡背景是亮色 (暗夜模式下)，使用系统主色
    final isTooltipDark = ThemeData.estimateBrightnessForColor(tooltipBgColor) == Brightness.dark;
    final aiButtonColor = isTooltipDark ? Colors.purpleAccent : primaryColor;

    return Stack(
      children: [
        Positioned(
          left: (anchor.dx - 120).clamp(10.0, MediaQuery.of(context).size.width - 250),
          top: anchor.dy,
          child: Material(
            elevation: isFlat ? 0 : 8,
            color: tooltipBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
              side: isFlat ? BorderSide(color: currentTheme.backgroundColor.withValues(alpha: 0.2), width: 1) : BorderSide.none,
            ),
            child: Container(
              height: toolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuButton(label: '剪切', onTap: () => handleCut(delegate), textColor: tooltipTextColor, iconColor: tooltipIconColor),
                  _MenuButton(label: '复制', onTap: () => handleCopy(delegate), textColor: tooltipTextColor, iconColor: tooltipIconColor),
                  _MenuButton(label: '粘贴', onTap: () => handlePaste(delegate), textColor: tooltipTextColor, iconColor: tooltipIconColor),
                  _MenuButton(
                      label: '选段',
                      icon: Icons.segment,
                      onTap: _onSelectParagraph,
                      textColor: tooltipTextColor,
                      iconColor: tooltipIconColor
                  ),
                  _MenuButton(
                    label: 'AI',
                    icon: Icons.auto_awesome,
                    iconColor: aiButtonColor, // 【应用智能高亮色】
                    textColor: aiButtonColor,
                    onTap: _onAiClick,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.icon,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final splashColor = textColor.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      splashColor: splashColor,
      highlightColor: splashColor,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
                label,
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}