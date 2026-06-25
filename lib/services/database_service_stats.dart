import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/models/book/daily_stats.dart';

/// ── 每日写作统计 ──────────────────────────────────────

mixin StatsMixin {
  Isar get isar;

  Future<void> updateDailyStats(int delta, String bookTitle, String chapterTitle) async {
    if (delta == 0) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timeStr = DateFormat('HH:mm').format(now);

    await isar.writeTxn(() async {
      DailyStats? stats = await isar.dailyStats.filter().dateEqualTo(today).findFirst();

      if (stats == null) {
        stats = DailyStats()
          ..date = today
          ..wordCount = delta > 0 ? delta : 0
          ..updatedAt = now
          ..logs = [
            DailyLog()
              ..timeStr = timeStr
              ..bookTitle = bookTitle
              ..chapterTitle = chapterTitle
              ..wordCountChange = delta
          ];
      } else {
        stats.wordCount += delta;
        if (stats.wordCount < 0) stats.wordCount = 0;
        stats.updatedAt = now;

        final currentLogs = stats.logs.toList();
        final existingLogIndex = currentLogs.indexWhere(
            (log) => log.bookTitle == bookTitle && log.chapterTitle == chapterTitle);

        if (existingLogIndex != -1) {
          final log = currentLogs[existingLogIndex];
          log.wordCountChange += delta;
          log.timeStr = timeStr;
          currentLogs[existingLogIndex] = log;
        } else {
          currentLogs.insert(
              0,
              DailyLog()
                ..timeStr = timeStr
                ..bookTitle = bookTitle
                ..chapterTitle = chapterTitle
                ..wordCountChange = delta);
        }
        stats.logs = currentLogs;
      }
      await isar.dailyStats.put(stats);
    });
  }

  Future<int> getTodayWordCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stats = await isar.dailyStats.filter().dateEqualTo(today).findFirst();
    return stats?.wordCount ?? 0;
  }

  Future<int> getTotalWordCount() async =>
      await isar.books.filter().isDeletedEqualTo(false).wordCountProperty().sum();

  Future<int> getConsecutiveDays() async {
    final statsList =
        await isar.dailyStats.filter().wordCountGreaterThan(0).sortByDateDesc().findAll();
    if (statsList.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latestDate = statsList.first.date;
    if (today.difference(latestDate).inDays > 1) return 0;

    DateTime checkDate = today;
    if (!statsList.any((s) => s.date.isAtSameMomentAs(today))) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    final activeDays = statsList.map((e) => e.date).toSet();
    if (activeDays.contains(checkDate)) {
      streak++;
      for (int d = 1; d < 3650; d++) {
        if (activeDays.contains(checkDate.subtract(Duration(days: d)))) {
          streak++;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  Future<List<DailyStats>> getWeeklyStats() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return await isar.dailyStats
        .filter()
        .dateGreaterThan(today.subtract(const Duration(days: 7)))
        .sortByDate()
        .findAll();
  }

  Future<DailyStats?> getPeakRecord() async =>
      await isar.dailyStats.where().sortByWordCountDesc().findFirst();

  Future<int> getActiveDaysCount() async =>
      await isar.dailyStats.filter().wordCountGreaterThan(0).count();

  Future<List<DailyStats>> getMonthlyStats(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));
    return await isar.dailyStats.filter().dateBetween(start, end).sortByDate().findAll();
  }

  Future<List<DailyStats>> getCurrentMonthStats() async => getMonthlyStats(DateTime.now());
}
