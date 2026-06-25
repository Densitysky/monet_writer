import 'package:isar/isar.dart';

part 'chapter.g.dart';

@collection
class Chapter {
  Id id = Isar.autoIncrement;

  @Index()
  late int bookId;

  late String title;

  // 纯文本内容 (保留用于向后兼容、字数统计、AI分析、txt导出等)
  late String content;

  // 【核心新增】：保存带有格式和段落间距的富文本 Delta JSON 数据
  String? contentDelta;

  // 本章细纲
  String? outline;

  int wordCount = 0;

  late int orderIndex;

  late DateTime updatedAt;
}