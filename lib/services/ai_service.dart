import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:monet_writer/models/ai/ai_config.dart';
import 'package:monet_writer/services/database_service.dart';

class AiService {
  /// 1. 统一文本生成接口
  static Future<String> generateText(
      AiConfig config, {
        required String systemPrompt,
        required String userPrompt,
      }) async {
    if (config.apiKey.isEmpty) {
      throw Exception('请先在设置中配置 API Key');
    }

    final finalSystemPrompt = (config.customPrompt != null && config.customPrompt!.isNotEmpty)
        ? config.customPrompt!
        : systemPrompt;

    try {
      if (config.provider == 'google') {
        return await _callGemini(config, finalSystemPrompt, userPrompt);
      } else {
        return await _callOpenAICompatible(config, finalSystemPrompt, userPrompt);
      }
    } catch (e) {
      debugPrint('AI Request Failed: $e');
      throw Exception('AI 请求失败: $e');
    }
  }

  /// 2. 获取模型列表接口
  static Future<List<String>> fetchModels(AiConfig config) async {
    if (config.apiKey.isEmpty) throw Exception('API Key 不能为空');

    try {
      if (config.provider == 'google') {
        return await _fetchGeminiModels(config);
      } else {
        return await _fetchOpenAIModels(config);
      }
    } catch (e) {
      debugPrint('Fetch Models Failed: $e');
      throw Exception('获取模型列表失败: $e');
    }
  }

  /// 3. 【核心修复】净化 AI 返回的文本，安全提取 JSON 字符串
  static String cleanJsonString(String rawAiResponse) {
    String cleaned = rawAiResponse.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    final startIndex = cleaned.indexOf(RegExp(r'[\{\[]'));
    final endIndex = cleaned.lastIndexOf(RegExp(r'[\}\]]'));

    if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
      return cleaned.substring(startIndex, endIndex + 1);
    }

    return cleaned;
  }

  // --- 内部实现 ---

  static Future<List<String>> _fetchGeminiModels(AiConfig config) async {
    // 【修复】使用加号拼接，避免被编辑器误识别为超链接格式
    final url = '[https://generativelanguage.googleapis.com/v1beta/models?key=](https://generativelanguage.googleapis.com/v1beta/models?key=)' + config.apiKey;
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> models = data['models'] ?? [];
      return models
          .map((m) => m['name'].toString().replaceFirst('models/', ''))
          .toList();
    } else {
      throw Exception('Google API Error: ${response.body}');
    }
  }

  static Future<List<String>> _fetchOpenAIModels(AiConfig config) async {
    final baseUrl = config.baseUrl.isEmpty ? '[https://api.openai.com/v1](https://api.openai.com/v1)' : config.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = cleanBaseUrl.endsWith('v1') ? '$cleanBaseUrl/models' : '$cleanBaseUrl/v1/models';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${config.apiKey}'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> list = data['data'] ?? [];
      return list.map((m) => m['id'].toString()).toList();
    } else {
      throw Exception('API Error (${response.statusCode}): ${response.body}');
    }
  }

  static Future<String> _callGemini(AiConfig config, String sys, String user) async {
    final model = config.modelName.isEmpty ? 'gemini-pro' : config.modelName;
    // 【修复】使用加号拼接，避免超链接识别问题
    final url = '[https://generativelanguage.googleapis.com/v1beta/models/](https://generativelanguage.googleapis.com/v1beta/models/)' + model + ':generateContent?key=' + config.apiKey;

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts": [{"text": "$sys\n\n$user"}]}]
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
        return "AI 没有返回任何内容 (可能是安全拦截)";
      }
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gemini Error: ${response.body}');
    }
  }

  static Future<String> _callOpenAICompatible(AiConfig config, String sys, String user) async {
    final baseUrl = config.baseUrl.isEmpty ? '[https://api.openai.com/v1](https://api.openai.com/v1)' : config.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = '$cleanBaseUrl/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode({
        "model": config.modelName,
        "messages": [
          {"role": "system", "content": sys},
          {"role": "user", "content": user}
        ],
        "temperature": 0.7,
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final bodyBytes = response.bodyBytes;
      final bodyString = utf8.decode(bodyBytes);
      final data = jsonDecode(bodyString);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('API Error (${response.statusCode}): ${response.body}');
    }
  }
}

class AiProvider extends ChangeNotifier {
  AiConfig _config = AiConfig();
  AiConfig get config => _config;

  List<String> _availableModels = [];
  List<String> get availableModels => _availableModels;
  List<String> get currentModelList => _availableModels;

  final Isar _isar = DatabaseService().isar;

  Future<void> loadConfig() async {
    final c = await _isar.aiConfigs.where().findFirst();
    if (c != null) {
      _config = c;
    } else {
      _config = AiConfig()..provider = 'google'..modelName = 'gemini-pro';
      await _isar.writeTxn(() async => await _isar.aiConfigs.put(_config));
    }
    notifyListeners();
  }

  Future<void> updateConfig({String? provider, String? apiKey, String? baseUrl, String? modelName, String? customPrompt}) async {
    if (provider != null) _config.provider = provider;
    if (apiKey != null) _config.apiKey = apiKey;
    if (baseUrl != null) _config.baseUrl = baseUrl;
    if (modelName != null) _config.modelName = modelName;
    if (customPrompt != null) _config.customPrompt = customPrompt;
    await _isar.writeTxn(() async {
      await _isar.aiConfigs.put(_config);
    });
    notifyListeners();
  }

  void updateModelList(List<String> models) {
    _availableModels = models;
    notifyListeners();
  }

  void setAvailableModels(List<String> models) {
    _availableModels = models;
    notifyListeners();
  }
}