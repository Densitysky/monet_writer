part of '../writing_provider.dart';

/// 零件九：专属 AI 提取与生成中枢 (将大模型逻辑彻底剥离 UI 层)
mixin WritingAiExtractionMixin on WritingProviderBase {

  // ==================== 1. 角色智能提取 ====================
  Future<int> extractCharactersFromContent(AiConfig config) async {
    final content = await getRecentContent(limit: 5);
    if (content.isEmpty) throw Exception('当前章节没有正文内容，无法提取。');

    const systemPrompt = '''
你是一个专业的小说助手。请提取以下正文片段中出场的所有角色。
返回格式必须是严格的 JSON，如下所示，不要包含任何额外的解释或 Markdown 标记：
{
  "characters": [
    {
      "name": "角色名",
      "description": "一句话简介",
      "role": "身份或设定",
      "bio": "详细背景"
    }
  ]
}
''';
    final userPrompt = "正文片段：\n$content";

    final rawResponse = await AiService.generateText(config, systemPrompt: systemPrompt, userPrompt: userPrompt);
    final cleanJson = AiService.cleanJsonString(rawResponse);
    final data = jsonDecode(cleanJson);

    if (data['characters'] != null && data['characters'] is List) {
      final list = data['characters'] as List;
      if (list.isEmpty) throw Exception('未在正文中检测到新角色');

      await batchAddCharacters(list);
      return list.length;
    } else {
      throw Exception('大模型返回数据格式异常，请重试。');
    }
  }

  // ==================== 2. 剧情细纲提取 ====================
  Future<Map<String, String>> generatePlotNodeFromContent(AiConfig config) async {
    final chapterContent = await getRecentContent(limit: 5);
    if (chapterContent.isEmpty) throw Exception('当前章节没有正文内容，无法提取剧情。');

    const systemPrompt = '''
你是一个专业的小说助手。请根据以下正文片段，总结出本章的剧情细纲节点。
返回格式必须是严格的 JSON，如下所示，不要包含任何额外的解释或 Markdown 标记：
{
  "title": "节点标题(不超过10个字)",
  "content": "剧情详细摘要(30-50字)"
}
''';
    final userPrompt = "正文片段：\n$chapterContent";

    final rawResponse = await AiService.generateText(config, systemPrompt: systemPrompt, userPrompt: userPrompt);
    final cleanJson = AiService.cleanJsonString(rawResponse);
    final data = jsonDecode(cleanJson);

    final title = data['title']?.toString();
    final contentStr = data['content']?.toString();

    if (title != null && title.isNotEmpty && contentStr != null) {
      return {'title': title, 'content': contentStr};
    } else {
      throw Exception('返回数据格式异常。');
    }
  }

  // ==================== 3. 宏观设定扩写 ====================
  Future<String> expandSettingWithAi(AiConfig config, String settingType, String currentText) async {
    final chapterContent = await getRecentContent(limit: 5);
    if (chapterContent.isEmpty && currentText.isEmpty) {
      throw Exception('正文和设定内容均为空，AI 缺乏参考上下文。');
    }

    final systemPrompt = '''
你是一个专业的小说设定架构师。请根据用户提供的现有设定和正文内容，对【$settingType】进行深度扩写和细节补全。
直接输出补全后的设定文本，不要任何引导语，不要使用 markdown 代码块包裹。
''';
    final userPrompt = "现有设定：\n${currentText.isEmpty ? '暂无' : currentText}\n\n近期正文参考：\n${chapterContent.isEmpty ? '暂无' : chapterContent}";

    final rawResponse = await AiService.generateText(config, systemPrompt: systemPrompt, userPrompt: userPrompt);

    // 纯文本模式，只需清理可能被强加的 Markdown 标记
    String newText = rawResponse.trim();
    newText = newText.replaceAll(RegExp(r'^```.*$', multiLine: true), '');
    newText = newText.replaceAll(RegExp(r'```$', multiLine: true), '');

    return newText.trim();
  }
}