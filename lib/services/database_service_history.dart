import 'package:isar/isar.dart';
import 'package:monet_writer/models/book/chapter_history.dart';

/// ── 章节历史快照 ──────────────────────────────────────

mixin HistoryMixin {
  Isar get isar;

  Future<bool> saveChapterHistory(int chapterId, String content, int wordCount) async {
    try {
      final history = ChapterHistory()
        ..chapterId = chapterId
        ..content = content
        ..wordCount = wordCount
        ..timestamp = DateTime.now();
      await isar.writeTxn(() async {
        await isar.chapterHistorys.put(history);
        final count =
            await isar.chapterHistorys.filter().chapterIdEqualTo(chapterId).count();
        if (count > 50) {
          final oldestRecords = await isar.chapterHistorys
              .filter()
              .chapterIdEqualTo(chapterId)
              .sortByTimestamp()
              .limit(count - 50)
              .findAll();
          await isar.chapterHistorys.deleteAll(oldestRecords.map((e) => e.id).toList());
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ChapterHistory>> getChapterHistories(int chapterId) async =>
      await isar.chapterHistorys
          .filter()
          .chapterIdEqualTo(chapterId)
          .sortByTimestampDesc()
          .findAll();
}
