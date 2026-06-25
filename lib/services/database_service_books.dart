import 'dart:io';
import 'package:isar/isar.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/models/book/chapter.dart';

/// ── 书籍 & 章节 CRUD ──────────────────────────────────

mixin BooksMixin {
  Isar get isar;

  /// 返回值: true 表示写入成功, false 表示失败
  Future<bool> createBook(String title, {String? desc, String? coverPath}) async {
    try {
      final newBook = Book()
        ..title = title
        ..description = desc
        ..coverPath = coverPath
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.books.put(newBook);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Book>> getAllBooks() async =>
      await isar.books.filter().isDeletedEqualTo(false).sortByUpdatedAtDesc().findAll();

  Stream<List<Book>> watchDeletedBooks() =>
      isar.books.filter().isDeletedEqualTo(true).sortByUpdatedAtDesc().watch(fireImmediately: true);

  Future<bool> restoreBook(int bookId) async {
    try {
      await isar.writeTxn(() async {
        final book = await isar.books.get(bookId);
        if (book != null) {
          book.isDeleted = false;
          book.updatedAt = DateTime.now();
          await isar.books.put(book);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBookPermanently(int bookId) async {
    try {
      await isar.writeTxn(() async {
        await isar.chapters.filter().bookIdEqualTo(bookId).deleteAll();
        await isar.books.delete(bookId);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Chapter>> getChaptersForBook(int bookId) async =>
      await isar.chapters.filter().bookIdEqualTo(bookId).sortByOrderIndex().findAll();

  Future<bool> createChapter(int bookId, String title) async {
    try {
      await isar.writeTxn(() async {
        final count = await isar.chapters.filter().bookIdEqualTo(bookId).count();
        final newChapter = Chapter()
          ..bookId = bookId
          ..title = title
          ..content = ''
          ..orderIndex = count
          ..updatedAt = DateTime.now();
        await isar.chapters.put(newChapter);
        final book = await isar.books.get(bookId);
        if (book != null) {
          book.updatedAt = DateTime.now();
          await isar.books.put(book);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateChapterContent(int chapterId, String content, int wordCount,
      {String? contentDelta}) async {
    try {
      await isar.writeTxn(() async {
        final chapter = await isar.chapters.get(chapterId);
        if (chapter != null) {
          chapter.content = content;
          if (contentDelta != null) {
            chapter.contentDelta = contentDelta;
          }
          chapter.wordCount = wordCount;
          chapter.updatedAt = DateTime.now();
          await isar.chapters.put(chapter);
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ── TXT 导出 ─────────────────────────────────────────
  Future<bool> exportAllBooksToTxt(String outputDir) async {
    try {
      final books = await getAllBooks();
      for (var book in books) {
        final chapters = await getChaptersForBook(book.id);
        final sb = StringBuffer();
        sb.writeln('《${book.title}》');
        sb.writeln('作者：${book.authorName ?? "佚名"}');
        sb.writeln('\n======================================================\n');
        for (var chapter in chapters) {
          sb.writeln('【${chapter.title}】\n');
          sb.writeln(chapter.content);
          sb.writeln('\n------------------------------------------------------\n');
        }
        final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        await File('$outputDir/$safeTitle.txt').writeAsString(sb.toString());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
