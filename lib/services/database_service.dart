import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/models/chapter.dart';
import 'package:monet_writer/models/prompt_template.dart';
import 'package:monet_writer/models/daily_stats.dart';
import 'package:monet_writer/models/ai_config.dart';
import 'package:monet_writer/models/chapter_history.dart';
import 'package:monet_writer/models/trashed_chapter.dart';
import 'package:monet_writer/models/inspiration_fragment.dart';

import 'database_service_books.dart';
import 'database_service_stats.dart';
import 'database_service_history.dart';
import 'database_service_ai.dart';
import 'database_service_backup.dart';
import 'database_service_inspiration.dart';

/// 数据库核心 — 单例持有 Isar 实例
/// 业务方法通过 mixin 分布在领域文件中

class DatabaseService with BooksMixin, StatsMixin, HistoryMixin, AiMixin, BackupMixin, InspirationMixin {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Isar _isar;

  @override
  Isar get isar => _isar;

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
}
