import 'package:isar/isar.dart';
import 'package:monet_writer/models/ai/ai_config.dart';

/// ── AI 配置 CRUD ──────────────────────────────────────

mixin AiMixin {
  Isar get isar;

  Future<List<AiConfig>> getAllAiConfigs() async =>
      await isar.aiConfigs.where().findAll();

  Future<void> saveAiConfig(AiConfig config) async {
    await isar.writeTxn(() async {
      await isar.aiConfigs.put(config);
    });
  }

  Future<void> deleteAiConfig(int id) async {
    await isar.writeTxn(() async {
      await isar.aiConfigs.delete(id);
    });
  }
}
