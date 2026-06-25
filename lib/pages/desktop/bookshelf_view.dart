import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

import 'package:monet_writer/pages/desktop/home/components/desktop_book_card.dart';
import 'package:monet_writer/pages/desktop/home/components/desktop_book_dialog.dart';

class BookshelfView extends StatefulWidget {
  const BookshelfView({super.key});

  @override
  State<BookshelfView> createState() => _BookshelfViewState();
}

class _BookshelfViewState extends State<BookshelfView> {
  late Stream<List<Book>> _booksStream;

  @override
  void initState() {
    super.initState();
    // 监听 Isar 数据库中未删除的书籍，按最后修改时间倒序排列
    _booksStream = DatabaseService().isar.books
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  // 呼出居中的桌面级书籍编辑向导
  void _showCreateBookDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const DesktopBookDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return StreamBuilder<List<Book>>(
      stream: _booksStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('加载失败: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final books = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 1. 顶部 Header ====================
            Container(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('我的作品', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  const SizedBox(width: 16),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('共 ${books.length} 本', style: TextStyle(fontSize: 14, color: currentTheme.textColor.withValues(alpha: 0.5))),
                  ),

                  const Spacer(),

                  // 用一个居中对齐的 Row 把搜索框和按钮包起来，彻底解决高低不齐！
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 注入灵魂：带呼吸焦点环的绝美搜索框
                      _FocusableSearchBar(
                        currentTheme: currentTheme,
                        isFlat: isFlat,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(width: 16),

                      // 新建书籍按钮 (强制锁定 40px 高度，与搜索框绝对平齐)
                      SizedBox(
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: _showCreateBookDialog,
                          icon: const Icon(CupertinoIcons.add, size: 16),
                          label: const Text('新建书籍', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================== 2. 书籍网格展示区 ====================
            Expanded(
              child: books.isEmpty
                  ? _buildEmptyView(currentTheme, isFlat, primaryColor)
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(40, 10, 40, 40),
                // 【核心重构】：完美适配竖向画廊风的全新网格比例
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180, // 宽度大幅收紧，变身精美长条卡片
                  mainAxisExtent: 310,     // 高度拉长，完美契合实体书的 3:4 黄金比例
                  crossAxisSpacing: 32,    // 增加卡片间的左右间距，更有呼吸感
                  mainAxisSpacing: 32,     // 增加上下间距
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return DesktopBookCard(book: books[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 绝美桌面级空状态
  Widget _buildEmptyView(WritingTheme theme, bool isFlat, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: theme.textColor.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.book, size: 48, color: theme.textColor.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text('书架空空如也', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 8),
          Text('点击右上角或下方按钮，开启你的新故事', style: TextStyle(fontSize: 14, color: theme.textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _showCreateBookDialog,
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: const Text('创建第一本书', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 100.0)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 桌面级专属微交互：带呼吸光晕的搜索框 (Spotlight 质感)
/// ==========================================
class _FocusableSearchBar extends StatefulWidget {
  final WritingTheme currentTheme;
  final bool isFlat;
  final Color primaryColor;

  const _FocusableSearchBar({
    required this.currentTheme,
    required this.isFlat,
    required this.primaryColor,
  });

  @override
  State<_FocusableSearchBar> createState() => _FocusableSearchBarState();
}

class _FocusableSearchBarState extends State<_FocusableSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // 监听焦点变化，触发动画渲染
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: _isFocused ? 260 : 240, // 聚焦时微微变长一点，引导输入
      height: 40, // 强制绝对高度 40px
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.currentTheme.textColor.withValues(alpha: _isFocused ? 0.02 : 0.05),
        borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 20.0),
        border: Border.all(
          // 聚焦时边框染上主题色
          color: _isFocused
              ? widget.primaryColor.withValues(alpha: 0.4)
              : (widget.isFlat ? widget.currentTheme.textColor.withValues(alpha: 0.1) : Colors.transparent),
          width: 1.0,
        ),
        boxShadow: _isFocused
            ? [
          // 核心：聚焦时的 macOS 级柔和呼吸光晕
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              CupertinoIcons.search,
              key: ValueKey(_isFocused),
              size: 16,
              color: _isFocused ? widget.primaryColor : widget.currentTheme.textColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              style: TextStyle(fontSize: 13, color: widget.currentTheme.textColor),
              decoration: InputDecoration(
                hintText: '搜索书籍...',
                hintStyle: TextStyle(color: widget.currentTheme.textColor.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true, // 极其关键：剥夺 Flutter 默认占位留白
                contentPadding: EdgeInsets.zero, // 强制内部绝对居中对齐
              ),
            ),
          ),
        ],
      ),
    );
  }
}