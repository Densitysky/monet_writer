import 'package:isar/isar.dart';

part 'chapter_history.g.dart';

@collection
class ChapterHistory {
  Id id = Isar.autoIncrement;

  @Index()
  late int chapterId; // 关联的章节 ID

  late String content; // 历史版本正文内容

  late int wordCount; // 历史版本字数

  @Index()
  late DateTime timestamp; // 记录生成的时间戳
}