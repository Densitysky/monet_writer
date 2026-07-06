part of '../writing_provider.dart';

/// 零件二：章节初始化、自动保存、字数统计与无缝切换
mixin WritingChapterMixin on WritingProviderBase {

  // 【核心新增】：防高度覆写锁
  bool _isRestoringScroll = false;

  // ==================== 初始化与保存 ====================

  @override
  Future<void> _initAsync() async {
    final chapters = await _isar.chapters
        .filter()
        .bookIdEqualTo(book.id)
        .sortByOrderIndex()
        .findAll();

    if (chapters.isEmpty) {
      await createChapter('第 1 章');
      return;
    }

    if (book.lastChapterId != null) {
      currentChapter = chapters.where((c) => c.id == book.lastChapterId).firstOrNull;
    }
    currentChapter ??= chapters.firstOrNull;

    if (currentChapter != null) {
      titleController.text = currentChapter!.title;
      contentController.loadData(
        plainText: currentChapter!.content,
        deltaJson: currentChapter!.contentDelta,
      );
      _lastText = currentChapter!.content;

      // 开始像素与光标级空降
      _restoreScrollPosition(currentChapter!);
    }

    _refreshNameCache();
    notifyListeners();
  }

  @override
  Future<void> saveCurrentChapter() async {
    if (currentChapter == null) return;
    isSaving = true;
    notifyListeners();

    final newContent = contentController.getPlainText();
    final newDelta = contentController.getDeltaJson();
    final title = titleController.text;

    final oldLen = currentChapter!.wordCount;
    final newLen = newContent.replaceAll(RegExp(r'\s+'), '').length;
    final delta = newLen - oldLen;

    currentChapter!.title = title;
    currentChapter!.content = newContent;
    currentChapter!.contentDelta = newDelta;
    currentChapter!.wordCount = newLen;
    currentChapter!.updatedAt = DateTime.now();

    // 【双轨记忆】：同时记下屏幕的滚动高度，以及光标的具体位置
    if (scrollController.hasClients && !_isRestoringScroll) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monet_scroll_${currentChapter!.id}', scrollController.offset);

      final currentCursor = contentController.selection.baseOffset;
      if (currentCursor >= 0) {
        await prefs.setInt('monet_cursor_${currentChapter!.id}', currentCursor);
      }
    }

    await _isar.writeTxn(() async {
      await _isar.chapters.put(currentChapter!);
      book.updatedAt = DateTime.now();
      book.wordCount = (book.wordCount + delta) < 0 ? 0 : (book.wordCount + delta);
      await _isar.books.put(book);
    });

    if (delta != 0) {
      await DatabaseService().updateDailyStats(delta, book.title, title);
    }

    isDirty = false;
    isSaving = false;
    notifyListeners();
  }

  @override
  void onContentChanged() {
    isDirty = true;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      saveCurrentChapter();
    });
  }

  void onTextChanged() => onContentChanged();

  // ==================== 章节与书籍管理 ====================

  @override
  Future<void> selectChapter(Chapter chapter) async {
    if (currentChapter?.id == chapter.id) return;

    // 【双轨记忆】：离开当前章节前，记下高度和光标
    if (currentChapter != null && scrollController.hasClients && !_isRestoringScroll) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monet_scroll_${currentChapter!.id}', scrollController.offset);

      final currentCursor = contentController.selection.baseOffset;
      if (currentCursor >= 0) {
        await prefs.setInt('monet_cursor_${currentChapter!.id}', currentCursor);
      }
    }

    if (isDirty) await saveCurrentChapter();

    currentChapter = chapter;
    titleController.text = chapter.title;

    contentController.loadData(
      plainText: chapter.content,
      deltaJson: chapter.contentDelta,
    );
    _lastText = chapter.content;

    isDirty = false;
    undoController.value = UndoHistoryValue.empty;

    // 开始新章节像素与光标级空降
    _restoreScrollPosition(chapter);

    await _isar.writeTxn(() async {
      book.lastChapterId = chapter.id;
      await _isar.books.put(book);
    });
    notifyListeners();

    // 空章节光标定位到标题
    if ((chapter.content == null || chapter.content!.isEmpty) && (chapter.contentDelta == null || chapter.contentDelta!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => titleFocusNode.requestFocus());
    }
  }

  Future<void> switchChapter(Chapter chapter) => selectChapter(chapter);

  @override
  Future<void> createChapter(String title) async {
    if (isDirty) await saveCurrentChapter();
    final count = await _isar.chapters.filter().bookIdEqualTo(book.id).count();

    final newChapter = Chapter()
      ..bookId = book.id
      ..title = title
      ..content = ''
      ..contentDelta = null
      ..orderIndex = count
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.chapters.put(newChapter);
      book.updatedAt = DateTime.now();
      await _isar.books.put(book);
    });

    await selectChapter(newChapter);
  }

  Future<void> loadChapterByIndex(int index) async {
    final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).sortByOrderIndex().findAll();
    if (index >= 0 && index < chapters.length) {
      await selectChapter(chapters[index]);
    }
  }

  Future<bool> switchToPreviousChapter() async {
    if (currentChapter == null) return false;
    final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).sortByOrderIndex().findAll();
    final currentIndex = chapters.indexWhere((c) => c.id == currentChapter!.id);

    if (currentIndex > 0) {
      await selectChapter(chapters[currentIndex - 1]);
      return true;
    }
    return false;
  }

  Future<bool> switchToNextChapter() async {
    if (currentChapter == null) return false;
    final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).sortByOrderIndex().findAll();
    final currentIndex = chapters.indexWhere((c) => c.id == currentChapter!.id);

    if (currentIndex >= 0 && currentIndex < chapters.length - 1) {
      await selectChapter(chapters[currentIndex + 1]);
      return true;
    }
    return false;
  }

  @override
  Future<String> getRecentContent({int limit = 5}) async {
    if (currentChapter == null) return '';
    return currentChapter!.content;
  }

  // ==================== 终极空降轮询机制 ====================

  Future<void> _restoreScrollPosition(Chapter chapter) async {
    _isRestoringScroll = true; // 上锁，禁止自动保存覆盖高度

    final prefs = await SharedPreferences.getInstance();
    final savedOffset = prefs.getDouble('monet_scroll_${chapter.id}') ?? 0.0;
    final savedCursor = prefs.getInt('monet_cursor_${chapter.id}');

    // 1. 恢复光标位置（剥离 Quill 底层的隐藏换行符误差）
    final rawText = contentController.text;
    final pureTextLength = (rawText.isNotEmpty && rawText.endsWith('\n'))
        ? rawText.length - 1
        : rawText.length;

    int targetCursor = savedCursor ?? pureTextLength; // 没存过就定位到末尾
    if (targetCursor > pureTextLength) targetCursor = pureTextLength;
    if (targetCursor < 0) targetCursor = 0;

    contentController.selection = TextSelection.collapsed(offset: targetCursor);

    // 2. 开始高频轮询，等排版完成后恢复屏幕滚动高度
    _tryRestoreScroll(savedOffset, 0);
  }

  void _tryRestoreScroll(double targetOffset, int attempts) {
    if (attempts > 20) {
      // 连续尝试了 1 秒，彻底超时，强制解锁
      _isRestoringScroll = false;
      return;
    }

    if (scrollController.hasClients) {
      final maxOffset = scrollController.position.maxScrollExtent;
      // 必须确保排版已经撑开高度 (maxOffset > 0)，或者用户本来就在最顶部 (targetOffset == 0)
      if (maxOffset > 0 || targetOffset == 0) {
        final safeOffset = targetOffset > maxOffset ? maxOffset : targetOffset;
        scrollController.jumpTo(safeOffset);
        _isRestoringScroll = false; // 成功空降，解除锁定
        return;
      }
    }

    // 还没排版完，隔 50 毫秒再查水表！绝不放过
    Future.delayed(const Duration(milliseconds: 50), () => _tryRestoreScroll(targetOffset, attempts + 1));
  }
}