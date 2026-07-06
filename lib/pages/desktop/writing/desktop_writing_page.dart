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
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  final int _inspectorTabIndex = 0;
  bool _showSearchPanel = false;
  late final ValueNotifier<int> _inspectorTabController;
  late final ValueNotifier<String?> _aiSelectedText;

  static const double _leftPanelWidth = 260.0;
  static const double _rightPanelWidth = 300.0;
  static const double _cardMargin = 12.0;

  @override
  void initState() {
    super.initState();
    _inspectorTabController = ValueNotifier<int>(_inspectorTabIndex);
    _aiSelectedText = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _inspectorTabController.dispose();
    _aiSelectedText.dispose();
    super.dispose();
  }

  void _onAiTap(String selectedText) {
    setState(() {
      _showRightPanel = true;
      _inspectorTabController.value = 3;
      _aiSelectedText.value = selectedText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();
    final isPaper = themeProvider.isPaperOrParchment;
    final currentTheme = userProvider.currentTheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          provider.saveCurrentChapter();
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
              // ── 三栏布局 ──
              Row(
                children: [
                  // 左浮动卡片：章节目录
                  if (_showLeftPanel)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_cardMargin, _cardMargin, _cardMargin / 2, _cardMargin),
                      child: _SideCard(
                        width: _leftPanelWidth,
                        isPaper: isPaper,
                        currentTheme: currentTheme,
                        child: const DesktopChapterPanel(),
                      ),
                    ),

                  // 中央编辑器
                  Expanded(
                    child: DesktopEditorPanel(
                      onBack: () => Navigator.pop(context),
                      onAiTap: _onAiTap,
                    ),
                  ),

                  // 右浮动卡片：百宝箱
                  if (_showRightPanel)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_cardMargin / 2, _cardMargin, _cardMargin, _cardMargin),
                      child: _SideCard(
                        width: _rightPanelWidth,
                        isPaper: isPaper,
                        currentTheme: currentTheme,
                        child: DesktopInspectorPanel(
                      initialTab: _inspectorTabIndex,
                      tabController: _inspectorTabController,
                      aiSelectedText: _aiSelectedText,
                    ),
                      ),
                    ),
                ],
              ),

              // 面板切换按钮（悬浮在编辑器边缘）
              Positioned(
                left: _showLeftPanel ? _leftPanelWidth + _cardMargin * 1.5 : 0,
                top: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _showLeftPanel = !_showLeftPanel),
                  child: Container(
                    width: 20,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 16, height: 48,
                        decoration: BoxDecoration(
                          color: currentTheme.textColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.horizontal(
                            left: _showLeftPanel ? Radius.zero : const Radius.circular(8),
                            right: _showLeftPanel ? const Radius.circular(8) : Radius.zero,
                          ),
                        ),
                        child: Icon(
                          _showLeftPanel ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
                          size: 12, color: currentTheme.textColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: _showRightPanel ? _rightPanelWidth + _cardMargin * 1.5 : 0,
                top: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _showRightPanel = !_showRightPanel),
                  child: Container(
                    width: 20,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 16, height: 48,
                        decoration: BoxDecoration(
                          color: currentTheme.textColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.horizontal(
                            left: _showRightPanel ? const Radius.circular(8) : Radius.zero,
                            right: _showRightPanel ? Radius.zero : const Radius.circular(8),
                          ),
                        ),
                        child: Icon(
                          _showRightPanel ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
                          size: 12, color: currentTheme.textColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 搜索面板 ──
              if (_showSearchPanel)
                Positioned(
                  top: 48, right: _cardMargin + (_showRightPanel ? _rightPanelWidth + 20 : 8),
                  child: DesktopSearchPanel(
                    provider: provider,
                    onClose: () => setState(() => _showSearchPanel = false),
                  ),
                ),

              // ── 底部状态栏 ──
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildStatusBar(currentTheme, provider, userProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(WritingTheme currentTheme, WritingProvider provider, UserProvider userProvider) {
    final mutedColor = currentTheme.textColor.withValues(alpha: 0.45);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('第 ${(provider.currentChapter?.orderIndex ?? -1) + 1} 章', style: TextStyle(fontSize: 11, color: mutedColor)),
          const SizedBox(width: 12),
          Text('${provider.currentChapter?.wordCount ?? 0} 字', style: TextStyle(fontSize: 11, color: mutedColor)),
          const SizedBox(width: 12),
          Text('行高 ${userProvider.lineHeight.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: mutedColor)),
          const Spacer(),
          Text('Ctrl+S 保存  ·  Ctrl+F 搜索', style: TextStyle(fontSize: 10, color: currentTheme.textColor.withValues(alpha: 0.15), letterSpacing: 1)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 悬浮侧边卡片容器
// ═══════════════════════════════════════════

class _SideCard extends StatelessWidget {
  final double width;
  final bool isPaper;
  final WritingTheme currentTheme;
  final Widget child;

  const _SideCard({
    required this.width,
    required this.isPaper,
    required this.currentTheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentTheme.backgroundColor.computeLuminance() < 0.5;
    final t = currentTheme.textColor;

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: isPaper
              ? currentTheme.backgroundColor
              : currentTheme.backgroundColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.withValues(alpha: 0.06)),
          boxShadow: isPaper
              ? [BoxShadow(color: t.withValues(alpha: isDark ? 0.18 : 0.06), blurRadius: 16, offset: const Offset(0, 4))]
              : [
                  BoxShadow(color: t.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 24, offset: const Offset(0, 8)),
                  BoxShadow(color: t.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

