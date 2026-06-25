import 'package:isar/isar.dart';

part 'daily_stats.g.dart';

@collection
class DailyStats {
  Id id = Isar.autoIncrement;

  /// 日期 (只有年月日，时分秒为0)
  @Index(unique: true)
  late DateTime date;

  /// 当日总码字数 (变化量)
  int wordCount = 0;

  /// 最后更新时间
  late DateTime updatedAt;

  /// 【新增】当日活动详情记录
  List<DailyLog> logs = [];
}

/// 【新增】嵌入式对象，记录具体的章节修改
@embedded
class DailyLog {
  String? timeStr;      // 记录时间点 (如 "14:30")
  String? bookTitle;    // 书名
  String? chapterTitle; // 章节名
  int wordCountChange = 0; // 该章节今日的字数变化
}
