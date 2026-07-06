import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

import 'package:monet_writer/pages/writing/components/writing_drawer.dart';
import 'package:monet_writer/pages/writing/components/keyboard_toolbar.dart';
import 'package:monet_writer/pages/writing/components/right_drawer_views/outline_view.dart';
import 'package:monet_writer/pages/writing/components/right_drawer_views/character_view.dart';
import 'package:monet_writer/pages/writing/components/right_drawer_views/settings_view.dart';
import 'package:monet_writer/pages/writing/components/ai_input_toolbar.dart';
import 'package:monet_writer/pages/writing/components/inspiration_panel.dart';
import 'package:monet_writer/pages/writing/components/search_replace_sheet.dart';
import 'package:monet_writer/pages/writing/components/history_bottom_sheet.dart';
import 'package:monet_writer/pages/writing/components/image_export_page.dart';
import 'package:monet_writer/pages/writing/components/word_goal_widget.dart';
import 'package:monet_writer/pages/writing/components/trash_bottom_sheet.dart';
import 'package:monet_writer/widgets/editor/monet_rich_editor.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class WritingPage extends StatelessWidget {
  final Book book;
  final int initialChapterIndex;

  const WritingPage({
    super.key,
    required this.book,
    this.initialChapterIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WritingProvider(book: book),
      child: _WritingPageContent(initialChapterIndex: initialChapterIndex),
    );
  }
}

class _WritingPageContent extends StatefulWidget {
  final int initialChapterIndex;
  const _WritingPageContent({required this.initialChapterIndex});

  @override
  State<_WritingPageContent> createState() => _WritingPageContentState();
}

class _WritingPageContentState extends State<_WritingPageContent> with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasInitialized = false;
  bool _isKeyboardVisible = false;
  bool _isEditorFocused = false;
  bool _showAiInput = false;
  bool _showAiPanel = false;
  bool _showTopBar = true;
  late AnimationController _topBarAnim;
  Timer? _hideTopBarTimer;
  FocusNode? _editorFocusNode;

  // 灵感助手：用于替换/撤销
  String? _lastReplacedText; // 替换前的原文
  int _lastReplacedStart = 0;
  int _lastReplacedEnd = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _topBarAnim = AnimationController(vsync: this, duration: MonetDurations.component);
    _topBarAnim.value = 1.0;
    _topBarAnim.addStatusListener(_onTopBarStatusChanged);
    _startAutoHide();
  }

  @override
  void dispose() {
    _editorFocusNode?.removeListener(_onEditorFocusChange);
    _disposeScrollListener();
    _topBarAnim.removeStatusListener(_onTopBarStatusChanged);
    WidgetsBinding.instance.removeObserver(this);
    _topBarAnim.dispose();
    _hideTopBarTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 切后台时强制保存
      final provider = context.read<WritingProvider>();
      if (provider.isDirty) provider.saveCurrentChapter();
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = newValue);
      if (newValue && _showTopBar) {
        // 键盘拉起：呼出顶栏
        _showTopBarTemporarily();
        // 延迟 350ms 等待键盘动画完成，再滚动到光标位置
        Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              final provider = context.read<WritingProvider>();
              final sc = provider.scrollController;
              if (!sc.hasClients) return;
              final text = provider.contentController.text;
              final sel = provider.contentController.selection;
              final cursorOffset = sel.baseOffset >= 0 && sel.baseOffset <= text.length
                  ? sel.baseOffset
                  : text.length;
              // 估算光标行号：统计光标前的换行符数量
              final beforeCursor = text.substring(0, cursorOffset);
              final cursorLine = '\n'.allMatches(beforeCursor).length;
              final user = context.read<UserProvider>();
              final estimatedLineH = user.fontSize * user.lineHeight;
              final cursorY = cursorLine * estimatedLineH;
              final maxScroll = sc.position.maxScrollExtent;
              final viewportH = sc.position.viewportDimension;
              // 光标在视口下方 → 滚动使其出现在上方 1/3 处
              if (cursorY > sc.offset + viewportH) {
                final target = (cursorY - viewportH / 3).clamp(0.0, maxScroll);
                sc.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              } else if (cursorY < sc.offset) {
                // 光标在视口上方 → 向上滚
                final target = (cursorY - viewportH / 3).clamp(0.0, maxScroll);
                sc.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              }
            } catch (_) {}
          });
        });
      } else if (!newValue && _showTopBar) {
        // 键盘收起：只在非沉浸模式下启动自动隐藏
        _startAutoHide();
      }
    }
  }

  bool get _canAutoHide => !_isKeyboardVisible && !_showAiPanel;

  void _startAutoHide() {
    _hideTopBarTimer?.cancel();
    _hideTopBarTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isEditorFocused && _canAutoHide) {
        _topBarAnim.reverse();
        _showTopBar = false;
        setState(() {});
      }
    });
  }

  void _onTopBarStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
      if (mounted) setState(() {});
    }
  }

  void _showTopBarTemporarily() {
    _hideTopBarTimer?.cancel();
    _topBarAnim.forward();
    _showTopBar = true;
    setState(() {});
    if (_canAutoHide) {
      _hideTopBarTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _canAutoHide) {
          _topBarAnim.reverse();
          _showTopBar = false;
          setState(() {});
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      if (widget.initialChapterIndex >= 0) {
        final provider = context.read<WritingProvider>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadChapterByIndex(widget.initialChapterIndex);
        });
      }
      _hasInitialized = true;
    }
    // 建立编辑器焦点监听
    final provider = context.read<WritingProvider>();
    if (_editorFocusNode != provider.editorFocusNode) {
      _editorFocusNode?.removeListener(_onEditorFocusChange);
      _editorFocusNode = provider.editorFocusNode;
      _editorFocusNode!.addListener(_onEditorFocusChange);
      _isEditorFocused = _editorFocusNode!.hasFocus;
    }
    if (MediaQuery.of(context).disableAnimations) {
      _topBarAnim.duration = Duration.zero;
    }
    // 自动滚动：每次文本变化后确保光标在可视区内（先移除旧 listener 防重复）
    _disposeScrollListener();
    provider.contentController.addListener(_onTextChangedForScroll);
  }

  void _onTextChangedForScroll() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final provider = context.read<WritingProvider>();
        final sc = provider.scrollController;
        if (!sc.hasClients) return;
        final pos = sc.position;
        // 用编辑器内部 focusNode/selection 推算光标大致位置，保持光标在 viewport 下 1/4 处
        final bottomTarget = sc.offset + pos.viewportDimension * 0.75;
        if (bottomTarget > pos.maxScrollExtent) {
          sc.jumpTo(pos.maxScrollExtent);
        }
      } catch (_) {}
    });
  }

  void _disposeScrollListener() {
    try { context.read<WritingProvider>().contentController.removeListener(_onTextChangedForScroll); } catch (_) {}
  }

  void _onEditorFocusChange() {
    if (mounted) {
      setState(() {
        _isEditorFocused = _editorFocusNode?.hasFocus ?? false;
      });
    }
  }

  void _closeAiInput() {
    setState(() {
      _showAiInput = false;
    });
    context.read<WritingProvider>().clearAiHighlight();
  }

  void _openAiPanel() {
    final provider = context.read<WritingProvider>();
    final sel = provider.contentController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _lastReplacedStart = sel.start;
      _lastReplacedEnd = sel.end;
    }
    setState(() => _showAiPanel = true);
  }

  void _closeAiPanel() {
    setState(() {
      _showAiPanel = false;
      _lastReplacedText = null;
    });
    context.read<WritingProvider>().clearAiHighlight();
  }

  void _onReplaceText(String newText, int start, int end) {
    final provider = context.read<WritingProvider>();
    final oldText = provider.contentController.text;
    // 保存原文用于撤销
    _lastReplacedText = oldText.substring(start, end);
    _lastReplacedStart = start;
    _lastReplacedEnd = start + newText.length; // 替换后的结束位置

    final newFull = oldText.replaceRange(start, end, newText);
    provider.contentController.text = newFull;
    provider.contentController.selection = TextSelection.collapsed(offset: start + newText.length);
    provider.onContentChanged();
    _showGestureToast('已替换原文（可撤销）');
  }

  void _onUndoReplace() {
    if (_lastReplacedText == null) return;
    final provider = context.read<WritingProvider>();
    final text = provider.contentController.text;
    final restoreEnd = _lastReplacedStart + _lastReplacedText!.length;
    final newFull = text.replaceRange(_lastReplacedStart, _lastReplacedEnd, _lastReplacedText!);
    provider.contentController.text = newFull;
    provider.contentController.selection = TextSelection.collapsed(offset: restoreEnd);
    provider.onContentChanged();
    setState(() => _lastReplacedText = null);
    _showGestureToast('已撤销替换，原文已恢复');
  }

  void _toggleAiPanel() {
    if (_showAiPanel) {
      _closeAiPanel();
    } else {
      _openAiPanel();
    }
  }

  void _showGestureToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
    );
  }

  /// 退出写作页：有未保存内容则静默自动保存，不弹窗阻塞
  Future<bool> _onWillPop() async {
    final provider = context.read<WritingProvider>();
    if (provider.isDirty) {
      await provider.saveCurrentChapter();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();
    final isPaper = context.watch<ThemeProvider>().isPaperOrParchment;

    final hasChapter = provider.currentChapter != null;
    final wordCount = provider.contentController.text.replaceAll(RegExp(r'\s+'), '').length;

    final backgroundColor = userProvider.currentTheme.backgroundColor;
    final headerTextColor = userProvider.currentTheme.textColor.withValues(alpha: 0.7);
    final txtColor = userProvider.currentTheme.textColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _onWillPop();
        if (canExit && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (d) {
            if (d.localPosition.dy < 60 && !_showTopBar) {
              _showTopBarTemporarily();
            } else if (_showTopBar && _canAutoHide) {
              _startAutoHide();
            }
          },
          child: Container(
            decoration: BoxDecoration(color: backgroundColor),
            child: SafeArea(
              child: Column(
                children: [
                  // 顶部栏 — 自动收起，轻触顶部呼出
                  AnimatedBuilder(
                    animation: _topBarAnim,
                    builder: (context, child) {
                      return AnimatedSize(
                        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.component,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _topBarAnim.value > 0.01
                            ? Opacity(
                                opacity: _topBarAnim.value,
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.only(left: 4, right: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(CupertinoIcons.chevron_back, size: 22, color: headerTextColor),
                                        onPressed: () async {
                                          final canExit = await _onWillPop();
                                          if (canExit && mounted) Navigator.pop(context);
                                        },
                                      ),
                                      Expanded(
                                        child: TextField(
                                          focusNode: provider.titleFocusNode,
                                          controller: provider.titleController,
                                          enabled: hasChapter,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => provider.editorFocusNode.requestFocus(),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                            hintText: hasChapter ? '无标题' : '暂无章节',
                                            hintStyle: TextStyle(color: headerTextColor.withValues(alpha: 0.3)),
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: txtColor, overflow: TextOverflow.ellipsis),
                                          onChanged: (_) => provider.onTextChanged(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          WordGoalWidget(currentWordCount: hasChapter ? wordCount : 0),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),

                  // 正文区域
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              if (hasChapter)
                                Positioned.fill(
                                  child: AnimatedSwitcher(
                                    duration: MonetDurations.component,
                                    switchInCurve: MonetCurves.entry,
                                    switchOutCurve: MonetCurves.exit,
                                    transitionBuilder: (child, animation) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.03, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Theme(
                                      key: ValueKey(provider.currentChapter?.id),
                                    data: Theme.of(context).copyWith(
                                      scrollbarTheme: ScrollbarThemeData(
                                        thumbColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.dragged)) return txtColor.withValues(alpha: 0.4);
                                          return txtColor.withValues(alpha: 0.15);
                                        }),
                                        thickness: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.dragged)) return 8.0;
                                          return 3.0;
                                        }),
                                        radius: const Radius.circular(8),
                                        interactive: true,
                                        crossAxisMargin: 2,
                                      ),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        top: (!_showTopBar && _topBarAnim.value < 0.01) ? 80.0 : 24.0,
                                      ),
                                      child: Scrollbar(
                                      controller: provider.scrollController,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onDoubleTap: () {
                                          if (_isKeyboardVisible) return;
                                          if (_showTopBar) {
                                            _topBarAnim.reverse();
                                            _showTopBar = false;
                                            setState(() {});
                                          } else {
                                            _showTopBarTemporarily();
                                          }
                                        },
                                        onHorizontalDragEnd: (details) async {
                                          final velocity = details.primaryVelocity ?? 0;
                                          if (velocity > 500) {
                                            final success = await provider.switchToPreviousChapter();
                                            if (success) {
                                              HapticFeedback.lightImpact();
                                              if (mounted) _showGestureToast('已切换至：${provider.currentChapter?.title ?? "上一章"}');
                                            } else {
                                              HapticFeedback.vibrate();
                                              if (mounted) _showGestureToast('已经是第一章啦');
                                            }
                                          } else if (velocity < -500) {
                                            final success = await provider.switchToNextChapter();
                                            if (success) {
                                              HapticFeedback.lightImpact();
                                              if (mounted) _showGestureToast('已切换至：${provider.currentChapter?.title ?? "下一章"}');
                                            } else {
                                              HapticFeedback.vibrate();
                                              if (mounted) _showGestureToast('已经是最新一章啦');
                                            }
                                          }
                                        },
                                        child: MonetRichEditor(
                                          controller: provider.contentController,
                                          focusNode: provider.editorFocusNode,
                                          scrollController: provider.scrollController,
                                          scrollable: true,
                                          expands: true,
                                          hintText: '开始创作...',
                                          padding: EdgeInsets.only(
                                            left: 28,
                                            right: 28,
                                            bottom: provider.isTypewriterMode ? MediaQuery.of(context).size.height * 0.6 : (_isKeyboardVisible ? 140.0 : 80.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                                )
                              else
                                FadeSlideEntrance(
                                  delayMs: 100,
                                  child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.book, size: 64, color: headerTextColor.withValues(alpha: 0.2)),
                                      const SizedBox(height: 16),
                                      Text('当前无可用章节', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerTextColor)),
                                      const SizedBox(height: 8),
                                      Text('请在左侧目录中新建或从废纸篓恢复', style: TextStyle(fontSize: 13, color: headerTextColor.withValues(alpha: 0.5))),
                                      const SizedBox(height: 24),
                                      FilledButton.icon(
                                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                        icon: const Icon(Icons.menu_book, size: 18),
                                        label: const Text('打开目录'),
                                        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4 : 20))),
                                      ),
                                    ],
                                  ),
                                ),
                                ),

                              // 沉浸模式章节标题 — 左上角固定，正文在其下方滚动
                              if (!_showTopBar && hasChapter && _topBarAnim.value < 0.01)
                                Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: IgnorePointer(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 4),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(
                                          provider.currentChapter?.title ?? '无标题',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: headerTextColor.withValues(alpha: 0.55)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('双击退出沉浸模式', textAlign: TextAlign.left, style: TextStyle(fontSize: 11, color: headerTextColor.withValues(alpha: 0.35))),
                                      ]),
                                    ),
                                  ),
                                ),

                              // 底部信息栏 — 替代原 FAB（沉浸和顶栏模式下均可见）
                              if (hasChapter && !_showAiPanel)
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                    decoration: BoxDecoration(
                                      color: backgroundColor.withValues(alpha: 0.95),
                                      border: Border(top: BorderSide(color: txtColor.withValues(alpha: 0.06))),
                                    ),
                                    child: Row(children: [
                                      Expanded(child: Text('$wordCount 字', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txtColor))),
                                      GestureDetector(onTap: _showChapterList, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('章节', style: TextStyle(fontSize: 12, color: txtColor.withValues(alpha: 0.5))))),
                                      Container(width: 1, height: 16, color: txtColor.withValues(alpha: 0.1)),
                                      GestureDetector(onTap: () => _showQuickMenu(context, provider, userProvider, isPaper), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Icon(Icons.grid_view_rounded, size: 18, color: txtColor.withValues(alpha: 0.5)))),
                                      const SizedBox(width: 4),
                                      InkWell(onTap: _toggleAiPanel, borderRadius: BorderRadius.circular(18), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white))),
                                    ]),
                                  ),
                                ),

                              // AI 面板打开时显示关闭按钮（覆盖编辑区上方）
                              if (_showAiPanel && hasChapter)
                                Positioned(
                                  top: 0, left: 0, right: 0, bottom: 0,
                                  child: GestureDetector(
                                    onTap: _closeAiPanel,
                                    behavior: HitTestBehavior.translucent,
                                    child: Container(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.component,
                          curve: Curves.easeOutCubic,
                          width: _showAiPanel ? MediaQuery.of(context).size.width * 0.65 : 0,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: txtColor.withValues(alpha: 0.06), width: 1)),
                          ),
                          child: _showAiPanel
                              ? Builder(builder: (ctx) {
                                  final sel = provider.contentController.selection;
                                  final hasSel = sel.isValid && !sel.isCollapsed;
                                  return InspirationPanel(
                                    selectedText: hasSel ? sel.textInside(provider.contentController.text) : null,
                                    selectedStart: hasSel ? sel.start : null,
                                    selectedEnd: hasSel ? sel.end : null,
                                    onClose: _closeAiPanel,
                                    onReplaceText: _onReplaceText,
                                    onUndoReplace: _onUndoReplace,
                                    onTextCleared: _closeAiPanel,
                                  );
                                })
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  if (_showTopBar && hasChapter) ...[
                    AnimatedSwitcher(
                      duration: MonetDurations.component,
                      switchInCurve: MonetCurves.entry,
                      switchOutCurve: MonetCurves.exit,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: _showAiInput
                          ? AiInputToolbar(key: const ValueKey('ai_toolbar'), onClose: _closeAiInput)
                          : _isKeyboardVisible && _isEditorFocused
                              ? const KeyboardToolbar(key: ValueKey('kb_toolbar'))
                              : const SizedBox(key: ValueKey('empty_toolbar'), width: 0, height: 0),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context, WritingProvider provider, UserProvider user, bool isPaper) {
    _hideTopBarTimer?.cancel();
    final theme = user.currentTheme;
    final txt = theme.textColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: theme.backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(isPaper ? 0 : 20))),
        child: SafeArea(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!isPaper) Column(children: [const SizedBox(height: 8), Container(width: 40, height: 4, decoration: BoxDecoration(color: txt.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))]),
          const SizedBox(height: 8),
          _QuickMenuGroup(label: '章节', txt: txt, children: [
            _QItem(icon: CupertinoIcons.book, label: '列表', txt: txt, onTap: () { Navigator.pop(ctx); _showChapterList(); }),
            _QItem(icon: CupertinoIcons.add_circled, label: '新建', txt: txt, onTap: () { Navigator.pop(ctx); _showChapterCreate(); }),
            _QItem(icon: CupertinoIcons.trash, label: '废纸篓', txt: txt, onTap: () { Navigator.pop(ctx); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => TrashBottomSheet(provider: provider)); }),
          ]),
          _QuickMenuGroup(label: '创作', txt: txt, children: [
            _QItem(icon: CupertinoIcons.person_crop_circle, label: '角色', txt: txt, onTap: () { Navigator.pop(ctx); _showCharacterPage(); }),
            _QItem(icon: CupertinoIcons.bookmark, label: '大纲', txt: txt, onTap: () { Navigator.pop(ctx); _showOutlinePage(); }),
            _QItem(icon: CupertinoIcons.textformat_size, label: '排版', txt: txt, onTap: () { Navigator.pop(ctx); _openViewSheet('排版设置', const SettingsView()); }),
            _QItem(icon: CupertinoIcons.arrow_right_arrow_left, label: '智能排版', txt: txt, onTap: () async { Navigator.pop(ctx); await provider.smartCopyCurrentChapter(); if (context.mounted) _showGestureToast('已排版并复制到剪贴板'); }),
          ]),
          _QuickMenuGroup(label: '工具', txt: txt, children: [
            _QItem(icon: CupertinoIcons.search, label: '查找', txt: txt, onTap: () { Navigator.pop(ctx); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => SearchReplaceBottomSheet(provider: provider)); }),
            _QItem(icon: CupertinoIcons.clock, label: '时光机', txt: txt, onTap: () { Navigator.pop(ctx); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => HistoryBottomSheet(provider: provider)); }),
            _QItem(icon: CupertinoIcons.photo, label: '长图', txt: txt, onTap: () { Navigator.pop(ctx); Navigator.push(context, CupertinoPageRoute(builder: (_) => ImageExportPage(provider: provider))); }),
            _QItem(icon: CupertinoIcons.doc_text, label: '导出本章', txt: txt, onTap: () { Navigator.pop(ctx); provider.exportCurrentChapterTxt(); }),
            _QItem(icon: CupertinoIcons.book, label: '导出全书', txt: txt, onTap: () { Navigator.pop(ctx); provider.exportWholeBookTxt(); }),
            _QItem(icon: CupertinoIcons.doc_on_clipboard, label: '原文复制', txt: txt, onTap: () { Navigator.pop(ctx); provider.rawCopyCurrentChapter(); }),
            _QItem(icon: CupertinoIcons.arrow_down_to_line, label: '打字机', txt: txt, onTap: () { Navigator.pop(ctx); provider.toggleTypewriterMode(); }),
            _QItem(icon: CupertinoIcons.flag, label: '目标', txt: txt, onTap: () { Navigator.pop(ctx); _showGoalPicker(); }),
          ]),
          const SizedBox(height: 12),
        ]))),
      ),
    ).then((_) {
      if (mounted && _isEditorFocused && _canAutoHide) _startAutoHide();
    });
  }

  void _showChapterList() { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const WritingDrawer()); }

  void _showCharacterPage() {
    final t = context.read<UserProvider>().currentTheme;
    final wp = context.read<WritingProvider>();
    Navigator.push(context, CupertinoPageRoute(builder: (_) => ChangeNotifierProvider.value(
      value: wp,
      child: Scaffold(
        backgroundColor: t.backgroundColor,
        appBar: AppBar(
          backgroundColor: t.backgroundColor,
          title: Text('角色管理', style: TextStyle(color: t.textColor)),
          leading: IconButton(icon: Icon(CupertinoIcons.chevron_back, color: t.textColor), onPressed: () => Navigator.pop(context)),
        ),
        body: const CharacterView(),
      ),
    )));
  }

  void _showOutlinePage() {
    final t = context.read<UserProvider>().currentTheme;
    final wp = context.read<WritingProvider>();
    Navigator.push(context, CupertinoPageRoute(builder: (_) => ChangeNotifierProvider.value(
      value: wp,
      child: Scaffold(
        backgroundColor: t.backgroundColor,
        appBar: AppBar(
          backgroundColor: t.backgroundColor,
          title: Text('大纲梳理', style: TextStyle(color: t.textColor)),
          leading: IconButton(icon: Icon(CupertinoIcons.chevron_back, color: t.textColor), onPressed: () => Navigator.pop(context)),
        ),
        body: const OutlineView(),
      ),
    )));
  }

  void _showChapterCreate() {
    final isPaper = context.read<ThemeProvider>().isPaperOrParchment;
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4 : 20)),
      title: const Text('新建章节'), content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: '章节标题', border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4 : 12)))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () { if (c.text.isNotEmpty) { Navigator.pop(context); context.read<WritingProvider>().createChapter(c.text); } }, child: const Text('创建'))],
    ));
  }

  void _openViewSheet(String title, Widget view) {
    final t = context.read<UserProvider>().currentTheme;
    final isPaper = context.read<ThemeProvider>().isPaperOrParchment;
    final wp = context.read<WritingProvider>();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ChangeNotifierProvider.value(
      value: wp,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: t.backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(isPaper ? 0 : 20))),
        child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.textColor)), const Spacer(), IconButton(icon: Icon(CupertinoIcons.xmark, color: t.textColor.withValues(alpha: 0.5), size: 20), onPressed: () => Navigator.pop(context))])),
          Divider(height: 1, color: t.textColor.withValues(alpha: 0.1)), Expanded(child: view),
        ]),
      ),
    ));
  }

  void _showGoalPicker() {
    final t = context.read<UserProvider>().currentTheme;
    final isPaper = context.read<ThemeProvider>().isPaperOrParchment;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      decoration: BoxDecoration(color: t.backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(isPaper ? 0 : 20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16), Text('设定每日目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.textColor)), const SizedBox(height: 16),
        Wrap(spacing: 12, children: [1000,2000,3000,4000,5000].map((g) => InkWell(
          onTap: () async { await SharedPreferences.getInstance().then((p) => p.setInt('chapter_word_goal', g)); if (context.mounted) Navigator.pop(context); },
          borderRadius: BorderRadius.circular(isPaper ? 4 : 12),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: t.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isPaper ? 4 : 12)), child: Text('$g', style: TextStyle(color: t.textColor.withValues(alpha: 0.8)))),
        )).toList()), const SizedBox(height: 20),
      ])),
    ));
  }
}

class _QuickMenuGroup extends StatelessWidget {
  final String label;
  final Color txt;
  final List<Widget> children;
  const _QuickMenuGroup({required this.label, required this.txt, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(label, style: TextStyle(fontSize: 10, color: txt.withValues(alpha: 0.35), letterSpacing: 1))),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: children,
        ),
      ]),
    );
  }
}

class _QItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color txt;
  final VoidCallback onTap;
  const _QItem({required this.icon, required this.label, required this.txt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: txt.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: txt.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: txt.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

