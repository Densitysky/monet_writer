import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

import 'package:monet_writer/pages/writing/components/writing_drawer.dart';
import 'package:monet_writer/pages/writing/components/keyboard_toolbar.dart';
import 'package:monet_writer/pages/writing/components/right_drawer.dart';
import 'package:monet_writer/pages/writing/components/ai_input_toolbar.dart';
import 'package:monet_writer/pages/writing/components/more_actions_sheet.dart';
import 'package:monet_writer/pages/writing/components/word_goal_widget.dart';
import 'package:monet_writer/widgets/editor/monet_rich_editor.dart';
import 'package:monet_writer/widgets/save_before_exit_dialog.dart';
import 'package:monet_writer/widgets/edge_drawer_handle.dart';

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

class _WritingPageContentState extends State<_WritingPageContent> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasInitialized = false;
  bool _isKeyboardVisible = false;
  bool _showAiInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = newValue;
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
  }

  void _closeAiInput() {
    setState(() {
      _showAiInput = false;
    });
    context.read<WritingProvider>().clearAiHighlight();
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

  /// 尝试退出写作页，若内容未保存则弹出确认对话框
  Future<bool> _onWillPop() async {
    final provider = context.read<WritingProvider>();
    if (!provider.isDirty) return true;

    final shouldExit = await SaveBeforeExitDialog.show(
      context,
      title: '内容尚未保存',
      subtitle: '当前章节有未保存的修改，是否保存后再退出？',
      onSaveAndExit: () async {
        await provider.saveCurrentChapter();
      },
      onDiscardAndExit: () {},
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;

    final hasChapter = provider.currentChapter != null;
    final wordCount = provider.contentController.text.replaceAll(RegExp(r'\s+'), '').length;

    BoxDecoration? bgDecoration;
    final backgroundColor = userProvider.currentTheme.backgroundColor;
    final headerTextColor = userProvider.currentTheme.textColor.withValues(alpha: 0.7);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _onWillPop();
        if (canExit && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        drawer: const WritingDrawer(),
        endDrawer: const RightDrawer(),
        drawerEnableOpenDragGesture: false,
        endDrawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: true,

        body: Container(
          decoration: bgDecoration ?? BoxDecoration(color: backgroundColor),
          child: SafeArea(
            child: Column(
              children: [
                // 顶部栏
                Container(
                  height: 50,
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.chevron_back, size: 22, color: headerTextColor),
                        onPressed: () async {
                          final canExit = await _onWillPop();
                          if (canExit && mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: provider.titleController,
                          enabled: hasChapter,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: userProvider.currentTheme.textColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (_) => provider.onTextChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: hasChapter ? () {
                              FocusScope.of(context).unfocus();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => MoreActionsSheet(provider: provider),
                              );
                            } : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(CupertinoIcons.ellipsis_circle, size: 22, color: headerTextColor.withValues(alpha: hasChapter ? 1.0 : 0.3)),
                            ),
                          ),
                          Container(width: 1, height: 12, color: headerTextColor.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                          WordGoalWidget(currentWordCount: hasChapter ? wordCount : 0),
                        ],
                      ),
                    ],
                  ),
                ),

                // 正文区域
                Expanded(
                  child: Stack(
                    children: [
                      if (hasChapter)
                        Positioned.fill(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                thumbColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.dragged)) {
                                    return userProvider.currentTheme.textColor.withValues(alpha: 0.4);
                                  }
                                  return userProvider.currentTheme.textColor.withValues(alpha: 0.15);
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
                            child: Scrollbar(
                              controller: provider.scrollController,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: MonetRichEditor(
                                    controller: provider.contentController,
                                    focusNode: provider.editorFocusNode,
                                    scrollController: provider.scrollController,
                                    scrollable: true,
                                    expands: true,
                                    hintText: '开始创作...',
                                    padding: EdgeInsets.only(
                                      top: 16,
                                      bottom: provider.isTypewriterMode
                                          ? MediaQuery.of(context).size.height * 0.6
                                          : (_isKeyboardVisible ? 140.0 : 80.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
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
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 左侧抽屉手柄（替代不可见双击热区）
                      EdgeDrawerHandle(
                        isLeft: true,
                        onOpen: () => _scaffoldKey.currentState?.openDrawer(),
                        color: userProvider.currentTheme.textColor,
                      ),

                      // 右侧抽屉手柄（替代不可见双击热区）
                      EdgeDrawerHandle(
                        isLeft: false,
                        onOpen: () => _scaffoldKey.currentState?.openEndDrawer(),
                        color: userProvider.currentTheme.textColor,
                      ),
                    ],
                  ),
                ),

                if (hasChapter) ...[
                  if (_showAiInput)
                    AiInputToolbar(onClose: _closeAiInput)
                  else if (_isKeyboardVisible)
                    const KeyboardToolbar(),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
