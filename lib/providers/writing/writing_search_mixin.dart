part of '../writing_provider.dart';

/// 搜索结果统计模型
class SearchReport {
  final String query;
  final int totalBookMatches; // 全书总匹配数
  final int currentChapterMatches; // 本章匹配数
  final int affectedChaptersCount; // 受影响的章节数
  final Map<int, List<MatchItem>> chapterMatches; // 按章节ID分组的匹配详情

  SearchReport({
    required this.query,
    required this.totalBookMatches,
    required this.currentChapterMatches,
    required this.affectedChaptersCount,
    required this.chapterMatches,
  });
}

/// 单个匹配项详情 (用于 UI 展示上下文)
class MatchItem {
  final String chapterTitle;
  final int chapterId;
  final String previewContext; // 上下文摘要

  MatchItem({
    required this.chapterTitle,
    required this.chapterId,
    required this.previewContext,
  });
}

/// 零件六：全局搜索与替换核心逻辑
mixin WritingSearchMixin on WritingProviderBase {
  bool isSearching = false;

  // ==================== 1. 全局搜索逻辑 ====================

  /// 执行全局搜索，生成详细的搜索报告
  Future<SearchReport?> searchBook(String query) async {
    if (query.isEmpty) return null;

    isSearching = true;
    notifyListeners();

    int totalMatches = 0;
    int currentChapMatches = 0;
    Map<int, List<MatchItem>> chapterMatches = {};

    try {
      // 从数据库拉取本书所有章节
      final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).sortByOrderIndex().findAll();

      for (var chapter in chapters) {
        // 使用正在编辑的最新文本（如果遍历到当前章节）
        final textToSearch = (currentChapter?.id == chapter.id)
            ? contentController.text
            : chapter.content;

        int matchCount = 0;
        List<MatchItem> items = [];
        int index = textToSearch.indexOf(query);

        while (index != -1) {
          matchCount++;
          totalMatches++;
          if (currentChapter?.id == chapter.id) {
            currentChapMatches++;
          }

          // 截取上下文摘要（前后各 15 个字符）
          int start = (index - 15 >= 0) ? index - 15 : 0;
          int end = (index + query.length + 15 <= textToSearch.length)
              ? index + query.length + 15
              : textToSearch.length;

          String preview = textToSearch.substring(start, end).replaceAll('\n', ' ');
          if (start > 0) preview = '...$preview';
          if (end < textToSearch.length) preview = '$preview...';

          // 为了避免 UI 列表过长卡顿，每个章节最多只提取前 5 条上下文摘要用于预览
          if (items.length < 5) {
            items.add(MatchItem(
              chapterTitle: chapter.title,
              chapterId: chapter.id,
              previewContext: preview,
            ));
          }

          index = textToSearch.indexOf(query, index + query.length);
        }

        if (matchCount > 0) {
          chapterMatches[chapter.id] = items;
        }
      }

      return SearchReport(
        query: query,
        totalBookMatches: totalMatches,
        currentChapterMatches: currentChapMatches,
        affectedChaptersCount: chapterMatches.length,
        chapterMatches: chapterMatches,
      );

    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  // ==================== 2. 替换逻辑 ====================

  /// 本章替换
  Future<void> replaceInCurrentChapter(String query, String replaceText) async {
    if (currentChapter == null || query.isEmpty) return;

    final currentText = contentController.text;
    if (!currentText.contains(query)) return;

    // 直接替换当前控制器文本
    final newText = currentText.replaceAll(query, replaceText);
    contentController.text = newText;

    // 光标移至末尾
    contentController.selection = TextSelection.collapsed(offset: newText.length);

    // 触发保存
    isDirty = true;
    notifyListeners();
    await saveCurrentChapter();
  }

  /// 全局替换 (带时光机快照保护)
  Future<int> replaceInAllChapters(String query, String replaceText) async {
    if (query.isEmpty) return 0;
    int totalReplaced = 0;

    isSearching = true; // 复用 loading 状态拦截 UI
    notifyListeners();

    try {
      final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).findAll();

      for (var chapter in chapters) {
        // 判断当前循环的是否是正在编辑的章节
        final isCurrentEditing = (currentChapter?.id == chapter.id);
        final textToSearch = isCurrentEditing ? contentController.text : chapter.content;

        if (textToSearch.contains(query)) {
          // ==========================================
          // 🛡️ 安全锁：在修改该章节前，强制存一次历史快照
          // ==========================================
          final currentWordCount = textToSearch.replaceAll(RegExp(r'\s+'), '').length;
          await DatabaseService().saveChapterHistory(chapter.id, textToSearch, currentWordCount);

          // 执行替换
          final matchCount = query.allMatches(textToSearch).length;
          totalReplaced += matchCount;
          final newText = textToSearch.replaceAll(query, replaceText);
          final newWordCount = newText.replaceAll(RegExp(r'\s+'), '').length;

          if (isCurrentEditing) {
            // 如果是当前章节，更新内存控制器并触发保存
            contentController.text = newText;
            isDirty = true;
            await saveCurrentChapter();
          } else {
            // 如果是其他章节，直接静默更新数据库
            chapter.content = newText;
            chapter.wordCount = newWordCount;
            chapter.updatedAt = DateTime.now();
            await _isar.writeTxn(() async {
              await _isar.chapters.put(chapter);
            });
          }
        }
      }

      // 重新计算全书总字数并更新书籍表
      await _recalculateBookTotalWords();

    } finally {
      isSearching = false;
      notifyListeners();
    }

    return totalReplaced;
  }

  /// 辅助方法：重新计算全书字数
  Future<void> _recalculateBookTotalWords() async {
    int totalWords = await _isar.chapters.filter().bookIdEqualTo(book.id).wordCountProperty().sum();
    await _isar.writeTxn(() async {
      final freshBook = await _isar.books.get(book.id);
      if (freshBook != null) {
        freshBook.wordCount = totalWords;
        await _isar.books.put(freshBook);
      }
    });
  }
}