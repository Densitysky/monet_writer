import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/models/book/chapter.dart';
import 'package:monet_writer/models/book/daily_stats.dart';
import 'package:monet_writer/models/ai/ai_config.dart';
import 'package:monet_writer/models/book/chapter_history.dart';
import 'package:monet_writer/models/book/trashed_chapter.dart';
import 'package:monet_writer/models/ai/prompt_template.dart';
import 'package:monet_writer/models/book/inspiration_fragment.dart';

/// ── ZIP 备份 & 恢复引擎 ───────────────────────────────
/// 依赖 BooksMixin.getAllBooks() — 确保 DatabaseService 同时 with BooksMixin

mixin BackupMixin {
  Isar get isar;

  /// 将所有数据（JSON + 物理文件 + 偏好设置）打包为 ZIP
  Future<void> exportAllDataToZip(String zipFilePath) async {
    final archive = Archive();

    // 1. 导出数据库核心 JSON
    final Map<String, dynamic> dbData = {};
    dbData['books'] = await isar.books.where().exportJson();
    dbData['chapters'] = await isar.chapters.where().exportJson();
    dbData['dailyStats'] = await isar.dailyStats.where().exportJson();
    dbData['aiConfigs'] = await isar.aiConfigs.where().exportJson();
    dbData['chapterHistorys'] = await isar.chapterHistorys.where().exportJson();
    dbData['trashedChapters'] = await isar.trashedChapters.where().exportJson();
    dbData['promptTemplates'] = await isar.promptTemplates.where().exportJson();
    dbData['inspirationFragments'] = await isar.inspirationFragments.where().exportJson();

    final dbJsonBytes = utf8.encode(jsonEncode(dbData));
    archive.addFile(ArchiveFile('database.json', dbJsonBytes.length, dbJsonBytes));

    // 2. 导出 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settingsData = {};
    for (var key in prefs.getKeys()) {
      if (key.startsWith('monet_scroll_') || key.startsWith('monet_cursor_')) continue;
      settingsData[key] = prefs.get(key);
    }
    final settingsJsonBytes = utf8.encode(jsonEncode(settingsData));
    archive.addFile(ArchiveFile('settings.json', settingsJsonBytes.length, settingsJsonBytes));

    // 3. 收集物理文件（封面、头像、背景图、字体）
    final Set<String> filePathsToPack = {};
    // 注意: getAllBooks() 来自 BooksMixin, 需要确保 DatabaseService 也 with BooksMixin
    final books = await isar.books.filter().isDeletedEqualTo(false).sortByUpdatedAtDesc().findAll();
    for (var book in books) {
      if (book.coverPath != null && File(book.coverPath!).existsSync()) {
        filePathsToPack.add(book.coverPath!);
      }
    }
    const pathKeys = [
      'user_avatar_path',
      'user_bg_path',
      'user_profile_cover_path',
      'setting_font_path',
    ];
    for (var key in pathKeys) {
      final path = prefs.getString(key);
      if (path != null && File(path).existsSync()) {
        filePathsToPack.add(path);
      }
    }
    for (var path in filePathsToPack) {
      final file = File(path);
      final fileName = p.basename(path);
      final fileBytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('assets/$fileName', fileBytes.length, fileBytes));
    }

    // 4. 压缩落盘
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes != null) {
      await File(zipFilePath).writeAsBytes(zipBytes);
    }
  }

  /// 解压 ZIP 并导入数据（含路径重写）
  Future<void> importDataFromZip(String zipFilePath) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) throw Exception("同步数据包不存在或已损坏");

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docDir = await getApplicationDocumentsDirectory();
    final Map<String, String> fileNameToNewPath = {};

    // 1. 释放物理文件到当前设备文档目录
    for (final file in archive) {
      if (file.isFile && file.name.startsWith('assets/')) {
        final fileName = p.basename(file.name);
        final newFilePath = p.join(docDir.path, fileName);
        final data = file.content as List<int>;
        await File(newFilePath).writeAsBytes(data);
        fileNameToNewPath[fileName] = newFilePath;
      }
    }

    // 2. 重写路径并导入数据库 JSON
    final dbFileArchive = archive.findFile('database.json');
    if (dbFileArchive != null) {
      final dbJsonStr = utf8.decode(dbFileArchive.content as List<int>);
      final Map<String, dynamic> dbData = jsonDecode(dbJsonStr);

      if (dbData.containsKey('books')) {
        for (var book in dbData['books']) {
          if (book['coverPath'] != null) {
            final fileName = p.basename(book['coverPath']);
            if (fileNameToNewPath.containsKey(fileName)) {
              book['coverPath'] = fileNameToNewPath[fileName];
            }
          }
        }
      }

      await isar.writeTxn(() async {
        await isar.clear();

        List<Map<String, dynamic>> parseList(String key) {
          if (dbData[key] == null) return [];
          return List<Map<String, dynamic>>.from(
              dbData[key].map((x) => Map<String, dynamic>.from(x)));
        }

        if (dbData.containsKey('books')) await isar.books.importJson(parseList('books'));
        if (dbData.containsKey('chapters')) {
          await isar.chapters.importJson(parseList('chapters'));
        }
        if (dbData.containsKey('dailyStats')) {
          await isar.dailyStats.importJson(parseList('dailyStats'));
        }
        if (dbData.containsKey('aiConfigs')) {
          await isar.aiConfigs.importJson(parseList('aiConfigs'));
        }
        if (dbData.containsKey('chapterHistorys')) {
          await isar.chapterHistorys.importJson(parseList('chapterHistorys'));
        }
        if (dbData.containsKey('trashedChapters')) {
          await isar.trashedChapters.importJson(parseList('trashedChapters'));
        }
        if (dbData.containsKey('promptTemplates')) {
          await isar.promptTemplates.importJson(parseList('promptTemplates'));
        }
        if (dbData.containsKey('inspirationFragments')) {
          await isar.inspirationFragments.importJson(parseList('inspirationFragments'));
        }
      });
    }

    // 3. 重写路径并导入 SharedPreferences
    final settingsFileArchive = archive.findFile('settings.json');
    if (settingsFileArchive != null) {
      final settingsJsonStr = utf8.decode(settingsFileArchive.content as List<int>);
      final Map<String, dynamic> settingsData = jsonDecode(settingsJsonStr);
      final prefs = await SharedPreferences.getInstance();

      for (var key in settingsData.keys) {
        var value = settingsData[key];
        const pathKeys = [
          'user_avatar_path',
          'user_bg_path',
          'user_profile_cover_path',
          'setting_font_path',
        ];
        if (pathKeys.contains(key) && value is String) {
          final fileName = p.basename(value);
          if (fileNameToNewPath.containsKey(fileName)) {
            value = fileNameToNewPath[fileName];
          }
        }
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, (value as List).cast<String>());
        }
      }
    }
  }
}
