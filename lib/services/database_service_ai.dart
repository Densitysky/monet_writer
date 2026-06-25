import 'package:isar/isar.dart';
import 'package:monet_writer/models/ai/ai_config.dart';

/// ── AI 配置 CRUD ──────────────────────────────────────

mixin AiMixin {
  Isar get isar;

  Future<List<AiConfig>> getAllAiConfigs() async =>
      await isar.aiConfigs.where().findAll();

  Future<bool> saveAiConfig(AiConfig config) async {
    try {
      await isar.writeTxn(() async {
        await isar.aiConfigs.put(config);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAiConfig(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.aiConfigs.delete(id);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
