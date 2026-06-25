part of '../writing_provider.dart';

/// 零件七：章节废纸篓核心逻辑 (隔离式软删除)
mixin WritingTrashMixin on WritingProviderBase {

  /// 获取当前书籍废纸篓中的所有章节
  Future<List<TrashedChapter>> getTrashedChapters() async {
    return await _isar.trashedChapters
        .filter()
        .bookIdEqualTo(book.id)
        .sortByDeletedAtDesc() // 按删除时间倒序排列
        .findAll();
  }

  /// 核心：将章节移入废纸篓 (软删除)
  Future<void> moveChapterToTrash(Chapter chapter) async {
    // 1. 生成一份废纸篓拷贝
    final trashed = TrashedChapter()
      ..originalChapterId = chapter.id
      ..bookId = chapter.bookId
      ..title = chapter.title
      ..content = chapter.content
      ..wordCount = chapter.wordCount
      ..orderIndex = chapter.orderIndex
      ..deletedAt = DateTime.now();

    await _isar.writeTxn(() async {
      // 2. 存入废纸篓表
      await _isar.trashedChapters.put(trashed);
      // 3. 从真实世界的章节表中彻底抹除
      await _isar.chapters.delete(chapter.id);

      // 4. 实时扣除书籍的总字数 (防止出现负数)
      final freshBook = await _isar.books.get(book.id);
      if (freshBook != null) {
        freshBook.wordCount = (freshBook.wordCount - chapter.wordCount).clamp(0, 99999999);
        freshBook.updatedAt = DateTime.now();
        await _isar.books.put(freshBook);
        book.wordCount = freshBook.wordCount; // 同步内存
      }
    });

    // 5. 如果删掉的刚好是用户现在正在看着的这一章，必须强制切走
    if (currentChapter?.id == chapter.id) {
      final remainingChapters = await _isar.chapters
          .filter()
          .bookIdEqualTo(book.id)
          .sortByOrderIndex()
          .findAll();

      if (remainingChapters.isNotEmpty) {
        await selectChapter(remainingChapters.last);
      } else {
        // 如果手狠把整本书删光了，系统自动兜底新建第一章
        await createChapter('第 1 章');
      }
    }
    notifyListeners();
  }

  /// 核心：从废纸篓中恢复章节
  Future<void> restoreChapterFromTrash(TrashedChapter trashed) async {
    // 1. 重新转生为正常的章节
    final restored = Chapter()
      ..bookId = trashed.bookId
      ..title = trashed.title
      ..content = trashed.content
      ..wordCount = trashed.wordCount
      ..orderIndex = trashed.orderIndex
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      // 2. 存回真实世界
      await _isar.chapters.put(restored);
      // 3. 从废纸篓中销毁
      await _isar.trashedChapters.delete(trashed.id);

      // 4. 把字数加回给书籍总字数
      final freshBook = await _isar.books.get(book.id);
      if (freshBook != null) {
        freshBook.wordCount += trashed.wordCount;
        freshBook.updatedAt = DateTime.now();
        await _isar.books.put(freshBook);
        book.wordCount = freshBook.wordCount;
      }
    });

    notifyListeners();
    // 5. 恢复后，十分贴心地自动跳转过去看一眼
    await selectChapter(restored);
  }

  /// 彻底粉碎 (物理删除)
  Future<void> hardDeleteTrashedChapter(TrashedChapter trashed) async {
    await _isar.writeTxn(() async {
      await _isar.trashedChapters.delete(trashed.id);
    });
    notifyListeners();
  }

  /// 一键清空废纸篓
  Future<void> emptyTrash() async {
    final list = await getTrashedChapters();
    await _isar.writeTxn(() async {
      for (var item in list) {
        await _isar.trashedChapters.delete(item.id);
      }
    });
    notifyListeners();
  }
}