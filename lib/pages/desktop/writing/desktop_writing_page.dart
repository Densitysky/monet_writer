import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

import 'package:monet_writer/pages/desktop/writing/desktop_chapter_panel.dart';
import 'package:monet_writer/pages/desktop/writing/desktop_editor_panel.dart';
import 'package:monet_writer/pages/desktop/writing/desktop_inspector_panel.dart';
import 'package:monet_writer/pages/desktop/writing/desktop_search_panel.dart';
import 'package:monet_writer/pages/desktop/writing/components/desktop_ai_task_manager.dart';

class DesktopWritingPage extends StatelessWidget {
  final Book book;

  const DesktopWritingPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WritingProvider(book: book),
      child: const _DesktopWritingWorkspace(),
    );
  }
}

class _DesktopWritingWorkspace extends StatefulWidget {
  const _DesktopWritingWorkspace();

  @override
  State<_DesktopWritingWorkspace> createState() => _DesktopWritingWorkspaceState();
}

class _DesktopWritingWorkspaceState extends State<_DesktopWritingWorkspace> {
  // ================= 核心状态流转 =================
  bool _showSearchPanel = false;

  // 独立控制左右侧边栏的开关 (默认展开)
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;

    // 左侧面板固定宽度250，右侧固定320
    const double leftPanelWidth = 250.0;
    const double rightPanelWidth = 320.0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          provider.saveCurrentChapter();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('💾 已保存当前章节', style: TextStyle(fontWeight: FontWeight.bold)), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.primary, duration: const Duration(seconds: 1)));
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          setState(() => _showSearchPanel = !_showSearchPanel);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          body: Stack(
            children: [
              // ==================== 底层 1：核心面板层 ====================
              Row(
                children: [
                  // 左侧目录面板
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: _showLeftPanel ? leftPanelWidth : 0,
                    decoration: BoxDecoration(color: isFlat ? currentTheme.backgroundColor : currentTheme.textColor.withValues(alpha: 0.02), border: isFlat ? Border(right: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.08), width: 1)) : null),
                    child: ClipRect(
                      // 【核心修复】：加上 OverflowBox，强行锁定内部布局宽度，杜绝收起时的溢出报错
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: leftPanelWidth,
                        maxWidth: leftPanelWidth,
                        child: const DesktopChapterPanel(),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          color: currentTheme.backgroundColor,
                          child: DesktopEditorPanel(
                            onBack: () => Navigator.pop(context),
                          ),
                        ),

                        if (_showSearchPanel)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: DesktopSearchPanel(
                              provider: provider,
                              onClose: () => setState(() => _showSearchPanel = false),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 右侧百宝箱面板
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: _showRightPanel ? rightPanelWidth : 0,
                    decoration: BoxDecoration(color: isFlat ? currentTheme.backgroundColor : currentTheme.textColor.withValues(alpha: 0.02), border: isFlat ? Border(left: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.08), width: 1)) : null),
                    child: ClipRect(
                      // 【核心修复】：加上 OverflowBox 锁定内部宽度
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: rightPanelWidth,
                        maxWidth: rightPanelWidth,
                        child: const DesktopInspectorPanel(),
                      ),
                    ),
                  ),
                ],
              ),

              // ==================== 表层 2：Z轴悬浮的物理边缘把手 ====================

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: _showLeftPanel ? leftPanelWidth - 7 : 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _EdgeCollapseButton(
                    isLeft: true,
                    isExpanded: _showLeftPanel,
                    onTap: () => setState(() => _showLeftPanel = !_showLeftPanel),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                right: _showRightPanel ? rightPanelWidth - 7 : 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _EdgeCollapseButton(
                    isLeft: false,
                    isExpanded: _showRightPanel,
                    onTap: () => setState(() => _showRightPanel = !_showRightPanel),
                  ),
                ),
              ),

              // 全局任务呼吸灯
              const DesktopAiTaskIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgeCollapseButton extends StatefulWidget {
  final bool isLeft;
  final bool isExpanded;
  final VoidCallback onTap;

  const _EdgeCollapseButton({
    required this.isLeft,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_EdgeCollapseButton> createState() => _EdgeCollapseButtonState();
}

class _EdgeCollapseButtonState extends State<_EdgeCollapseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;
    final primary = Theme.of(context).colorScheme.primary;

    IconData icon;
    if (widget.isLeft) {
      icon = widget.isExpanded ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right;
    } else {
      icon = widget.isExpanded ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _isHovered ? 18.0 : 12.0,
          height: _isHovered ? 56.0 : 44.0,
          decoration: BoxDecoration(
            color: _isHovered ? primary : theme.textColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _isHovered ? primary : theme.textColor.withValues(alpha: 0.1), width: 1),
            boxShadow: _isHovered ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 10,
                color: _isHovered ? Colors.white : theme.textColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}