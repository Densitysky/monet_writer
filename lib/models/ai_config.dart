import 'package:isar/isar.dart';

part 'ai_config.g.dart';

@collection
class AiConfig {
  Id id = Isar.autoIncrement;

  /// 服务商: google, openai, silicon, deepseek
  String provider = 'google';

  /// API Key
  String apiKey = '';

  /// Base URL (OpenAI 格式接口专用)
  String baseUrl = '';

  /// 模型名称 (如 gemini-pro, deepseek-chat)
  String modelName = '';

  /// 【关键修复】新增字段，解决 getter not defined 报错
  String? customPrompt;
}
