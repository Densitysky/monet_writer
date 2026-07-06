
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/services/ai_service.dart';
import 'package:monet_writer/models/ai/ai_config.dart';

class AiConfigPage extends StatefulWidget {
  const AiConfigPage({super.key});

  @override
  State<AiConfigPage> createState() => _AiConfigPageState();
}

class _AiConfigPageState extends State<AiConfigPage> {
  final _keyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();

  bool _isTesting = false;
  bool _isFetchingModels = false;
  bool _showAdvanced = false; // 是否展开高级设置

  @override
  void initState() {
    super.initState();
    final config = context.read<AiProvider>().config;

    // MiMo：根据 Key 前缀自动选择 Base URL
    if (config.provider == 'mimo') {
      _baseUrlCtrl.text = _mimoBaseUrl(config.apiKey);
    } else {
      _baseUrlCtrl.text = config.baseUrl;
    }

    _keyCtrl.text = config.apiKey;
    _promptCtrl.text = config.customPrompt ?? '';
    if (_baseUrlCtrl.text.isNotEmpty || _promptCtrl.text.isNotEmpty) _showAdvanced = true;
  }

  /// Key → Base URL
  static String _mimoBaseUrl(String key) {
    if (key.startsWith('tp-')) return 'https://token-plan-cn.xiaomimimo.com/v1';
    if (key.startsWith('sk-')) return 'https://api.xiaomimimo.com/v1';
    return 'https://token-plan-cn.xiaomimimo.com/v1';
  }
  void dispose() {
    _keyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AiProvider>().config;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 模型配置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // AI 服务商
            DropdownButtonFormField<String>(
              value: config.provider,
              decoration: const InputDecoration(
                labelText: 'AI 服务商',
                prefixIcon: Icon(Icons.cloud_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'google', child: Text('Google Gemini')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI / 兼容接口')),
                DropdownMenuItem(value: 'silicon', child: Text('硅基流动 (SiliconFlow)')),
                DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek 官方')),
                DropdownMenuItem(value: 'mimo', child: Text('小米 MiMo')),
                DropdownMenuItem(value: 'custom', child: Text('自定义 (OpenAI 格式)')),
              ],
              onChanged: (val) {
                if (val == null) return;
                context.read<AiProvider>().updateConfig(provider: val);
                if (val == 'silicon') {
                  _baseUrlCtrl.text = 'https://api.siliconflow.cn/v1';
                } else if (val == 'deepseek') {
                  _baseUrlCtrl.text = 'https://api.deepseek.com';
                } else if (val == 'mimo') {
                  _baseUrlCtrl.text = 'https://token-plan-cn.xiaomimimo.com/v1';
                } else if (val == 'google') {
                  _baseUrlCtrl.text = '';
                }
                _saveConfig();
              },
            ),

            const SizedBox(height: 16),

            // API Key
            TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API Key',
                prefixIcon: Icon(Icons.key_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (_) => _saveConfig(),
            ),

            const SizedBox(height: 16),

            // 模型名称
            DropdownButtonFormField<String>(
              value: config.modelName.isEmpty ? null : config.modelName,
              decoration: const InputDecoration(
                labelText: '模型名称',
                prefixIcon: Icon(Icons.smart_toy_outlined),
                border: OutlineInputBorder(),
              ),
              hint: const Text('请选择或手动输入'),
              items: [
                ...context.watch<AiProvider>().availableModels.map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: (val) {
                if (val == null) return;
                context.read<AiProvider>().updateConfig(modelName: val);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: config.modelName),
                    decoration: const InputDecoration(
                      hintText: '手动输入模型名',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (val) => context.read<AiProvider>().updateConfig(modelName: val),
                  ),
                ),
                const SizedBox(width: 8),
                _isFetchingModels
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '刷新模型列表',
                        onPressed: _fetchModels,
                      ),
              ],
            ),

            const SizedBox(height: 12),

            // 高级设置
            GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, size: 20),
                  const SizedBox(width: 4),
                  const Text('高级设置', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showAdvanced
                  ? Padding(
                      key: const ValueKey('advanced'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _baseUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Base URL (OpenAI 兼容格式)',
                              prefixIcon: Icon(Icons.link),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _saveConfig(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _promptCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: '自定义系统提示词 (System Prompt)',
                              prefixIcon: Icon(Icons.edit_note),
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            onChanged: (_) => _saveConfig(),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.wifi_tethering),
              label: Text(_isTesting ? '测试中...' : '测试连接（保存并验证）'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfig() {
    context.read<AiProvider>().updateConfig(
      apiKey: _keyCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      customPrompt: _promptCtrl.text.trim(),
    );
  }

  Future<void> _fetchModels() async {
    setState(() => _isFetchingModels = true);
    try {
      _saveConfig();
      final models = await AiService.fetchModels(context.read<AiProvider>().config);
      if (mounted) {
        context.read<AiProvider>().setAvailableModels(models);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功获取 ${models.length} 个模型')));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('获取模型列表失败', style: TextStyle(color: Colors.red)),
            content: Text('Exception: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingModels = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      _saveConfig();
      final response = await AiService.generateText(
        context.read<AiProvider>().config,
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: 'Hello, are you working?',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接成功！回复：${response.substring(0, response.length > 30 ? 30 : response.length)}...')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }
}
