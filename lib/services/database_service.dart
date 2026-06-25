import 'dart:io';
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// 【核心新增】：引入 Zip 压缩核心库，以及偏好设置和路径解析
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/models/chapter.dart';
import 'package:monet_writer/models/prompt_template.dart';
import 'package:monet_writer/models/daily_stats.dart';
import 'package:monet_writer/models/ai_config.dart';
import 'package:monet_writer/models/chapter_history.dart';
import 'package:monet_writer/models/trashed_chapter.dart';
import 'package:monet_writer/models/inspiration_fragment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Isar _isar;
  Isar get isar => _isar;

  /// 初始化数据库
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        BookSchema,
        ChapterSchema,
        PromptTemplateSchema,
        DailyStatsSchema,
        AiConfigSchema,
        ChapterHistorySchema,
        TrashedChapterSchema,
        InspirationFragmentSchema,
      ],
      directory: dir.path,
    );
  }

  // ==================== 数据统计核心逻辑 ====================

  Future<void> updateDailyStats(int delta, String bookTitle, String chapterTitle) async {
    if (delta == 0) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timeStr = DateFormat('HH:mm').format(now);

    await _isar.writeTxn(() async {
      DailyStats? stats = await _isar.dailyStats.filter().dateEqualTo(today).findFirst();

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

        List<DailyLog> currentLogs = stats.logs.toList();
        final existingLogIndex = currentLogs.indexWhere(
                (log) => log.bookTitle == bookTitle && log.chapterTitle == chapterTitle
        );

        if (existingLogIndex != -1) {
          final log = currentLogs[existingLogIndex];
          log.wordCountChange += delta;
          log.timeStr = timeStr;
          currentLogs[existingLogIndex] = log;
        } else {
          currentLogs.insert(0, DailyLog()
            ..timeStr = timeStr
            ..bookTitle = bookTitle
            ..chapterTitle = chapterTitle
            ..wordCountChange = delta
          );
        }
        stats.logs = currentLogs;
      }
      await _isar.dailyStats.put(stats);
    });
  }

  Future<int> getTodayWordCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stats = await _isar.dailyStats.filter().dateEqualTo(today).findFirst();
    return stats?.wordCount ?? 0;
  }

  Future<int> getTotalWordCount() async => await _isar.books.filter().isDeletedEqualTo(false).wordCountProperty().sum();

  Future<int> getConsecutiveDays() async {
    final statsList = await _isar.dailyStats.filter().wordCountGreaterThan(0).sortByDateDesc().findAll();
    if (statsList.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latestDate = statsList.first.date;
    if (today.difference(latestDate).inDays > 1) return 0;

    DateTime checkDate = today;
    if (!statsList.any((s) => s.date.isAtSameMomentAs(today))) checkDate = today.subtract(const Duration(days: 1));
    final activeDays = statsList.map((e) => e.date).toSet();
    if (activeDays.contains(checkDate)) {
      streak++;
      for (int d = 1; d < 3650; d++) {
        if (activeDays.contains(checkDate.subtract(Duration(days: d)))) streak++; else break;
      }
    }
    return streak;
  }

  Future<List<DailyStats>> getWeeklyStats() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return await _isar.dailyStats.filter().dateGreaterThan(today.subtract(const Duration(days: 7))).sortByDate().findAll();
  }

  Future<DailyStats?> getPeakRecord() async => await _isar.dailyStats.where().sortByWordCountDesc().findFirst();
  Future<int> getActiveDaysCount() async => await _isar.dailyStats.filter().wordCountGreaterThan(0).count();

  Future<List<DailyStats>> getMonthlyStats(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));
    return await _isar.dailyStats.filter().dateBetween(start, end).sortByDate().findAll();
  }
  Future<List<DailyStats>> getCurrentMonthStats() async => getMonthlyStats(DateTime.now());

  // ==================== 书籍与章节基础操作 ====================

  Future<void> createBook(String title, {String? desc, String? coverPath}) async {
    final newBook = Book()..title = title..description = desc..coverPath = coverPath..createdAt = DateTime.now()..updatedAt = DateTime.now();
    await _isar.writeTxn(() async { await _isar.books.put(newBook); });
  }

  Future<List<Book>> getAllBooks() async => await _isar.books.filter().isDeletedEqualTo(false).sortByUpdatedAtDesc().findAll();
  Stream<List<Book>> watchDeletedBooks() => _isar.books.filter().isDeletedEqualTo(true).sortByUpdatedAtDesc().watch(fireImmediately: true);

  Future<void> restoreBook(int bookId) async {
    await _isar.writeTxn(() async {
      final book = await _isar.books.get(bookId);
      if (book != null) { book.isDeleted = false; book.updatedAt = DateTime.now(); await _isar.books.put(book); }
    });
  }

  Future<void> deleteBookPermanently(int bookId) async {
    await _isar.writeTxn(() async {
      await _isar.chapters.filter().bookIdEqualTo(bookId).deleteAll();
      await _isar.books.delete(bookId);
    });
  }

  Future<List<Chapter>> getChaptersForBook(int bookId) async => await _isar.chapters.filter().bookIdEqualTo(bookId).sortByOrderIndex().findAll();

  Future<void> createChapter(int bookId, String title) async {
    await _isar.writeTxn(() async {
      final count = await _isar.chapters.filter().bookIdEqualTo(bookId).count();
      final newChapter = Chapter()..bookId = bookId..title = title..content = ''..orderIndex = count..updatedAt = DateTime.now();
      await _isar.chapters.put(newChapter);
      final book = await _isar.books.get(bookId);
      if (book != null) { book.updatedAt = DateTime.now(); await _isar.books.put(book); }
    });
  }

  Future<void> updateChapterContent(int chapterId, String content, int wordCount, {String? contentDelta}) async {
    await _isar.writeTxn(() async {
      final chapter = await _isar.chapters.get(chapterId);
      if (chapter != null) {
        chapter.content = content;
        if (contentDelta != null) {
          chapter.contentDelta = contentDelta;
        }
        chapter.wordCount = wordCount;
        chapter.updatedAt = DateTime.now();
        await _isar.chapters.put(chapter);
      }
    });
  }

  // ==================== AI 与历史配置 ====================
  Future<List<AiConfig>> getAllAiConfigs() async => await _isar.aiConfigs.where().findAll();
  Future<void> saveAiConfig(AiConfig config) async { await _isar.writeTxn(() async { await _isar.aiConfigs.put(config); }); }
  Future<void> deleteAiConfig(int id) async { await _isar.writeTxn(() async { await _isar.aiConfigs.delete(id); }); }

  Future<void> saveChapterHistory(int chapterId, String content, int wordCount) async {
    final history = ChapterHistory()..chapterId = chapterId..content = content..wordCount = wordCount..timestamp = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.chapterHistorys.put(history);
      final count = await _isar.chapterHistorys.filter().chapterIdEqualTo(chapterId).count();
      if (count > 50) {
        final oldestRecords = await _isar.chapterHistorys.filter().chapterIdEqualTo(chapterId).sortByTimestamp().limit(count - 50).findAll();
        await _isar.chapterHistorys.deleteAll(oldestRecords.map((e) => e.id).toList());
      }
    });
  }

  Future<List<ChapterHistory>> getChapterHistories(int chapterId) async => await _isar.chapterHistorys.filter().chapterIdEqualTo(chapterId).sortByTimestampDesc().findAll();

  Future<List<InspirationFragment>> getAllInspirationFragments() async =>
      await _isar.inspirationFragments.where().findAll();

  // ==================== 终极 Zip 备份与恢复引擎 ====================

  /// 核心升级：将所有数据（JSON + 图片物理文件 + 偏好设置）打包成 Zip！
  Future<void> exportAllDataToZip(String zipFilePath) async {
    final archive = Archive();

    // 1. 导出数据库核心 JSON 文本
    final Map<String, dynamic> dbData = {};
    dbData['books'] = await _isar.books.where().exportJson();
    dbData['chapters'] = await _isar.chapters.where().exportJson();
    dbData['dailyStats'] = await _isar.dailyStats.where().exportJson();
    dbData['aiConfigs'] = await _isar.aiConfigs.where().exportJson();
    dbData['chapterHistorys'] = await _isar.chapterHistorys.where().exportJson();
    dbData['trashedChapters'] = await _isar.trashedChapters.where().exportJson();
    dbData['promptTemplates'] = await _isar.promptTemplates.where().exportJson();
    dbData['inspirationFragments'] = await _isar.inspirationFragments.where().exportJson();

    final dbJsonBytes = utf8.encode(jsonEncode(dbData));
    archive.addFile(ArchiveFile('database.json', dbJsonBytes.length, dbJsonBytes));

    // 2. 导出所有全局设置 (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsData = {};
    for (var key in prefs.getKeys()) {
      // 【关键隔离】：只同步通用设置，刻意丢弃手机专用的设备状态（比如滚动高度和光标位置）
      if (key.startsWith('monet_scroll_') || key.startsWith('monet_cursor_')) continue;
      settingsData[key] = prefs.get(key);
    }

    final settingsJsonBytes = utf8.encode(jsonEncode(settingsData));
    archive.addFile(ArchiveFile('settings.json', settingsJsonBytes.length, settingsJsonBytes));

    // 3. 收集所有相关的物理图片与字体文件！
    final Set<String> filePathsToPack = {};

    // 扫描小说封面
    for (var book in await getAllBooks()) {
      if (book.coverPath != null && File(book.coverPath!).existsSync()) {
        filePathsToPack.add(book.coverPath!);
      }
    }

    // 扫描全局设置中的背景图、头像、自定义字体
    const pathKeys = ['user_avatar_path', 'user_bg_path', 'user_profile_cover_path', 'setting_font_path'];
    for (var key in pathKeys) {
      final path = prefs.getString(key);
      if (path != null && File(path).existsSync()) {
        filePathsToPack.add(path);
      }
    }

    // 将这些物理文件复制进 Zip 包的 `assets/` 目录下
    for (var path in filePathsToPack) {
      final file = File(path);
      final fileName = p.basename(path);
      final fileBytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('assets/$fileName', fileBytes.length, fileBytes));
    }

    // 4. 压缩并落盘
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes != null) {
      await File(zipFilePath).writeAsBytes(zipBytes);
    }
  }

  /// 核心升级：解压 Zip 包，并进行沙盒路径重写（Rewrite）！
  Future<void> importDataFromZip(String zipFilePath) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) throw Exception("同步数据包不存在或已损坏");

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docDir = await getApplicationDocumentsDirectory();

    // 记录文件原名到当前设备新绝对路径的映射
    Map<String, String> fileNameToNewPath = {};

    // 1. 首先释放所有的物理文件，存入当前设备的文档目录！
    for (final file in archive) {
      if (file.isFile && file.name.startsWith('assets/')) {
        final fileName = p.basename(file.name);
        final newFilePath = p.join(docDir.path, fileName);

        final data = file.content as List<int>;
        await File(newFilePath).writeAsBytes(data);

        // 登记护照（旧名 -> 新家地址）
        fileNameToNewPath[fileName] = newFilePath;
      }
    }

    // 2. 动态重写并导入数据库 JSON
    final dbFileArchive = archive.findFile('database.json');
    if (dbFileArchive != null) {
      final dbJsonStr = utf8.decode(dbFileArchive.content as List<int>);
      final Map<String, dynamic> dbData = jsonDecode(dbJsonStr);

      // 【动态重写】：将对方电脑上的路径，强行替换为我们刚才释放图片的新路径！
      if (dbData.containsKey('books')) {
        for (var book in dbData['books']) {
          if (book['coverPath'] != null) {
            final fileName = p.basename(book['coverPath']);
            if (fileNameToNewPath.containsKey(fileName)) {
              book['coverPath'] = fileNameToNewPath[fileName]; // 偷梁换柱！
            }
          }
        }
      }

      // 正式写入 Isar
      await _isar.writeTxn(() async {
        await _isar.clear();

        List<Map<String, dynamic>> parseList(String key) {
          if (dbData[key] == null) return [];
          return List<Map<String, dynamic>>.from(dbData[key].map((x) => Map<String, dynamic>.from(x)));
        }

        if (dbData.containsKey('books')) await _isar.books.importJson(parseList('books'));
        if (dbData.containsKey('chapters')) await _isar.chapters.importJson(parseList('chapters'));
        if (dbData.containsKey('dailyStats')) await _isar.dailyStats.importJson(parseList('dailyStats'));
        if (dbData.containsKey('aiConfigs')) await _isar.aiConfigs.importJson(parseList('aiConfigs'));
        if (dbData.containsKey('chapterHistorys')) await _isar.chapterHistorys.importJson(parseList('chapterHistorys'));
        if (dbData.containsKey('trashedChapters')) await _isar.trashedChapters.importJson(parseList('trashedChapters'));
        if (dbData.containsKey('promptTemplates')) await _isar.promptTemplates.importJson(parseList('promptTemplates'));
        if (dbData.containsKey('inspirationFragments')) await _isar.inspirationFragments.importJson(parseList('inspirationFragments'));
      });
    }

    // 3. 动态重写并导入全局设置 (SharedPreferences)
    final settingsFileArchive = archive.findFile('settings.json');
    if (settingsFileArchive != null) {
      final settingsJsonStr = utf8.decode(settingsFileArchive.content as List<int>);
      final Map<String, dynamic> settingsData = jsonDecode(settingsJsonStr);
      final prefs = await SharedPreferences.getInstance();

      for (var key in settingsData.keys) {
        var value = settingsData[key];

        // 【动态重写】：替换设置里的背景图、头像和字体路径
        const pathKeys = ['user_avatar_path', 'user_bg_path', 'user_profile_cover_path', 'setting_font_path'];
        if (pathKeys.contains(key) && value is String) {
          final fileName = p.basename(value);
          if (fileNameToNewPath.containsKey(fileName)) {
            value = fileNameToNewPath[fileName]; // 偷梁换柱！
          }
        }

        // 写入本地
        if (value is String) await prefs.setString(key, value);
        else if (value is int) await prefs.setInt(key, value);
        else if (value is double) await prefs.setDouble(key, value);
        else if (value is bool) await prefs.setBool(key, value);
        else if (value is List) await prefs.setStringList(key, (value as List).cast<String>());
      }
    }
  }

  // ==================== TXT 引擎 ====================

  Future<void> exportAllBooksToTxt(String outputDir) async {
    final books = await getAllBooks();
    for (var book in books) {
      final chapters = await getChaptersForBook(book.id);
      StringBuffer sb = StringBuffer();

      sb.writeln('《${book.title}》');
      sb.writeln('作者：${book.authorName ?? "佚名"}');
      sb.writeln('\n======================================================\n');

      for (var chapter in chapters) {
        sb.writeln('【${chapter.title}】\n');
        sb.writeln(chapter.content);
        sb.writeln('\n------------------------------------------------------\n');
      }

      final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('$outputDir/$safeTitle.txt');
      await file.writeAsString(sb.toString());
    }
  }
}