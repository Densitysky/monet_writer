import 'package:isar/isar.dart';

part 'trashed_chapter.g.dart';

/// 独立的废纸篓章节模型，完全隔离，防止污染正常章节查询
@collection
class TrashedChapter {
  Id id = Isar.autoIncrement;

  late int originalChapterId; // 记录它生前的 ID
  late int bookId; // 所属的书籍 ID

  late String title;
  late String content;
  late int wordCount;
  late int orderIndex; // 记录它生前在目录里的排序位置

  late DateTime deletedAt; // 被删除的时间，用于超过 30 天自动清理（预留扩展）
}