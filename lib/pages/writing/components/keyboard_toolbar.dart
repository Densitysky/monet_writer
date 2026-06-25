import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/utils/provider_select_ext.dart';

class KeyboardToolbar extends StatelessWidget {
  const KeyboardToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingProvider>();
    final currentTheme = context.selectCurrentTheme;
    final isFlat = context.selectIsFlat;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor.withValues(alpha: isFlat ? 1.0 : 0.9),
        border: isFlat ? Border(top: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))) : null,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // 1. 撤销/重做 (移到了第一顺位)
          ValueListenableBuilder<UndoHistoryValue>(
            valueListenable: provider.undoController,
            builder: (context, value, child) {
              return Row(
                children: [
                  _ToolbarIconButton(
                    icon: Icons.undo,
                    color: currentTheme.textColor.withValues(alpha: value.canUndo ? 0.8 : 0.2),
                    onPressed: value.canUndo ? () {
                      HapticFeedback.lightImpact();
                      provider.undoController.undo();
                    } : null,
                  ),
                  _ToolbarIconButton(
                    icon: Icons.redo,
                    color: currentTheme.textColor.withValues(alpha: value.canRedo ? 0.8 : 0.2),
                    onPressed: value.canRedo ? () {
                      HapticFeedback.lightImpact();
                      provider.undoController.redo();
                    } : null,
                  ),
                ],
              );
            },
          ),

          VerticalDivider(indent: 12, endIndent: 12, width: 20, color: currentTheme.textColor.withValues(alpha: 0.1)),

          // 2. 智能动态标点栏 (LRU 算法自动排序)
          ...provider.recentSymbols.map((symbol) {
            int offset = 0;
            if (['“”', '「」', '【】', '（）', '《》'].contains(symbol)) {
              offset = -1;
            }
            return _buildQuickInput(provider, symbol, offset, currentTheme, isFlat);
          }),

          VerticalDivider(indent: 12, endIndent: 12, width: 20, color: currentTheme.textColor.withValues(alpha: 0.1)),

          // 3. 收起键盘
          _ToolbarIconButton(
            icon: Icons.keyboard_hide,
            color: currentTheme.textColor.withValues(alpha: 0.7),
            onPressed: () => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInput(WritingProvider provider, String symbol, int offset, WritingTheme currentTheme, bool isFlat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          provider.recordAndInsertSymbol(symbol, offset);
        },
        style: TextButton.styleFrom(
          minimumSize: const Size(36, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 6.0)),
        ),
        child: Text(
            symbol,
            style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.8), fontSize: 13)
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  const _ToolbarIconButton({required this.icon, this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
    );
  }
}