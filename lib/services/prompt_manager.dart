import 'package:isar/isar.dart';
import 'package:monet_writer/models/ai/prompt_template.dart';
import 'package:monet_writer/services/database_service.dart';

/// 提示词管理器
/// 负责 Prompt 的获取、拼接、重置和更新
class PromptManager {

  static const String SCENE_CHAR_Extract = 'char_extract';
  static const String SCENE_CHAR_ANALYSIS = 'char_analysis';
  static const String SCENE_OUTLINE_NODE = 'outline_node'; // 【新增】章节细纲生成
  static const String SCENE_WORLD_SETTING = 'world_setting'; // 【新增】世界观/设定补全

  /// 获取构建好的 System Prompt (三明治成品)
  static Future<String> getSystemPrompt(String sceneCode) async {
    final isar = DatabaseService().isar;
    PromptTemplate? template = await isar.promptTemplates
        .filter()
        .sceneCodeEqualTo(sceneCode)
        .findFirst();

    if (template == null) {
      template = await _initDefaultTemplate(sceneCode);
    }

    if (template.isAdvancedMode && template.fullOverride != null) {
      return template.fullOverride!;
    }

    final buffer = StringBuffer();
    if (template.baseSystemPrompt != null) buffer.writeln(template.baseSystemPrompt!);
    if (template.userCustomPreference != null && template.userCustomPreference!.isNotEmpty) {
      buffer.writeln("\n【用户额外要求】\n${template.userCustomPreference!}");
    }
    if (template.formatConstraint != null) buffer.writeln("\n${template.formatConstraint!}");

    return buffer.toString();
  }

  /// 初始化默认模板
  static Future<PromptTemplate> _initDefaultTemplate(String sceneCode) async {
    final template = PromptTemplate()..sceneCode = sceneCode;

    if (sceneCode == SCENE_CHAR_Extract) {
      template.label = "章节角色提取";
      template.baseSystemPrompt = "你是一个小说辅助助手。请阅读正文，提取所有登场角色。";
      template.formatConstraint = '''
返回 JSON 数组，格式如下：
[
  {"name": "角色名", "description": "本章表现简介"}
]
只提取有具体名字的角色。忽略代词。
不要输出 markdown 代码块，直接返回 JSON 字符串。''';
      template.userCustomPreference = "";
    }
    else if (sceneCode == SCENE_CHAR_ANALYSIS) {
      template.label = "角色深度分析";
      template.baseSystemPrompt = "你是一个严谨的小说助手。请阅读用户提供的小说正文片段，总结指定角色的信息。";
      template.formatConstraint = '''
请返回严格的 JSON 格式：
{
  "description": "基于正文的一句话简介（30字内）",
  "bio": "基于正文的生平/性格/外貌总结",
  "tags": ["标签1", "标签2"],
  "events": [
    {
      "timePoint": "当前章节名（如：第十章）",
      "title": "本章该角色的核心行动（如：击败王嫣）",
      "content": "高度概括的剧情综述（50字内）"
    }
  ]
}
【重要规则】
1. 针对提供的章节内容，请将该角色在本章的经历**合并为唯一的一条事件**，不要拆分多条。
2. 如果该角色本章只是路人，没有实质性剧情，events 数组留空。
3. 严禁推测或编造。
不要输出 markdown 代码块，直接返回 JSON 字符串。''';
      template.userCustomPreference = "必须完全基于正文内容总结。";
    }
    // 【新增】大纲节点生成
    else if (sceneCode == SCENE_OUTLINE_NODE) {
      template.label = "章节细纲生成";
      template.baseSystemPrompt = "你是一个网文大纲策划师。请阅读当前章节正文，提炼出核心剧情节点。";
      template.formatConstraint = '''
请返回严格的 JSON 格式：
{
  "title": "简短的剧情标题（如：主角获得系统）",
  "content": "剧情梗概（100字以内，概括起承转合）"
}
不要输出 markdown 代码块，直接返回 JSON 字符串。''';
      template.userCustomPreference = "";
    }
    // 【新增】世界观/设定补全
    else if (sceneCode == SCENE_WORLD_SETTING) {
      template.label = "设定/世界观补全";
      template.baseSystemPrompt = "你是一个世界观架构师。请阅读小说正文，提取或补充相关的设定信息。";
      template.formatConstraint = "请直接返回补充后的设定文本，不要包含 JSON 格式，也不要包含“好的”、“以下是设定”等废话。直接输出内容。";
      template.userCustomPreference = "如果是对现有设定的补充，请保持风格一致。";
    }

    final isar = DatabaseService().isar;
    await isar.writeTxn(() async {
      await isar.promptTemplates.put(template);
    });

    return template;
  }

  static Future<void> updateUserPreference(String sceneCode, String preference) async {
    final isar = DatabaseService().isar;
    var template = await isar.promptTemplates.filter().sceneCodeEqualTo(sceneCode).findFirst();
    if (template != null) {
      await isar.writeTxn(() async {
        template.userCustomPreference = preference;
        template.updatedAt = DateTime.now();
        await isar.promptTemplates.put(template);
      });
    }
  }

  static Future<void> toggleAdvancedMode(String sceneCode, bool isAdvanced) async {
    final isar = DatabaseService().isar;
    var template = await isar.promptTemplates.filter().sceneCodeEqualTo(sceneCode).findFirst();
    if (template != null) {
      await isar.writeTxn(() async {
        template.isAdvancedMode = isAdvanced;
        if (isAdvanced && (template.fullOverride == null || template.fullOverride!.isEmpty)) {
          final currentSandwich = "${template.baseSystemPrompt}\n\n${template.userCustomPreference}\n\n${template.formatConstraint}";
          template.fullOverride = currentSandwich;
        }
        await isar.promptTemplates.put(template);
      });
    }
  }

  static Future<void> updateFullOverride(String sceneCode, String content) async {
    final isar = DatabaseService().isar;
    var template = await isar.promptTemplates.filter().sceneCodeEqualTo(sceneCode).findFirst();
    if (template != null) {
      await isar.writeTxn(() async {
        template.fullOverride = content;
        await isar.promptTemplates.put(template);
      });
    }
  }

  static Future<PromptTemplate> getTemplate(String sceneCode) async {
    final isar = DatabaseService().isar;
    var template = await isar.promptTemplates.filter().sceneCodeEqualTo(sceneCode).findFirst();
    return template ?? await _initDefaultTemplate(sceneCode);
  }
}
