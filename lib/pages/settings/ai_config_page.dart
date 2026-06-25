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
    _keyCtrl.text = config.apiKey;
    _baseUrlCtrl.text = config.baseUrl;
    _promptCtrl.text = config.customPrompt ?? '';

    // 如果有高级设置内容，默认展开
    if (_baseUrlCtrl.text.isNotEmpty || _promptCtrl.text.isNotEmpty) {
      _showAdvanced = true;
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  // --- 核心动作 1: 测试连接 (恢复) ---
  Future<void> _testConnection(AiProvider provider) async {
    if (_keyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入 API Key')));
      return;
    }

    setState(() => _isTesting = true);
    try {
      // 构建临时配置用于测试
      final tempConfig = AiConfig()
        ..provider = provider.config.provider
        ..apiKey = _keyCtrl.text
        ..baseUrl = _baseUrlCtrl.text
        ..modelName = provider.config.modelName
        ..customPrompt = _promptCtrl.text;

      final response = await AiService.generateText(
        tempConfig,
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: 'Reply "Connection OK" if you receive this.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试成功: $response'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog('连接失败', e.toString());
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  // --- 核心动作 2: 拉取模型列表 (恢复) ---
  Future<void> _fetchModelList(AiProvider provider) async {
    if (_keyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }

    setState(() => _isFetchingModels = true);
    try {
      final tempConfig = AiConfig()
        ..provider = provider.config.provider
        ..apiKey = _keyCtrl.text
        ..baseUrl = _baseUrlCtrl.text;

      final models = await AiService.fetchModels(tempConfig);

      if (mounted) {
        provider.setAvailableModels(models);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功获取 ${models.length} 个模型'), backgroundColor: Colors.green),
        );
        // 如果当前模型不在列表里，默认选第一个
        if (!models.contains(provider.config.modelName) && models.isNotEmpty) {
          provider.updateConfig(modelName: models.first);
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog('获取模型列表失败', e.toString());
    } finally {
      if (mounted) setState(() => _isFetchingModels = false);
    }
  }

  // 手动输入模型对话框
  void _showManualModelDialog(BuildContext context, AiProvider provider) {
    final ctrl = TextEditingController(text: provider.config.modelName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入模型名'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '例如: gpt-4o, deepseek-chat'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                // 更新模型名
                provider.updateConfig(modelName: ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();
    final config = provider.config;

    // 准备下拉列表数据
    final modelList = provider.availableModels;
    final dropdownItems = List<String>.from(modelList);
    // 确保当前选中的模型在列表里，否则加进去（避免 Dropdown 报错）
    if (config.modelName.isNotEmpty && !dropdownItems.contains(config.modelName)) {
      dropdownItems.insert(0, config.modelName);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI 模型配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 厂商选择
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'AI 服务商',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud_outlined),
            ),
            initialValue: config.provider,
            items: const [
              DropdownMenuItem(value: 'google', child: Text('Google Gemini')),
              DropdownMenuItem(value: 'openai', child: Text('OpenAI / 兼容接口')),
              DropdownMenuItem(value: 'silicon', child: Text('硅基流动 (SiliconFlow)')),
              DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek 官方')),
              DropdownMenuItem(value: 'custom', child: Text('自定义 (OpenAI 格式)')),
            ],
            onChanged: (val) {
              if (val != null) {
                // 切换厂商
                final newConfig = config..provider = val;
                provider.updateConfig(provider: val);

                // 自动填充 BaseURL (仅当输入框为空时，或者用户刚切换了厂商)
                if (val == 'silicon') {
                  _baseUrlCtrl.text = 'https://api.siliconflow.cn/v1';
                } else if (val == 'deepseek') {
                  _baseUrlCtrl.text = 'https://api.deepseek.com';
                } else if (val == 'google') {
                  _baseUrlCtrl.text = '';
                }
                // 同步更新 config 中的 baseUrl
                provider.updateConfig(baseUrl: _baseUrlCtrl.text);
              }
            },
          ),
          const SizedBox(height: 16),

          // 2. API Key
          TextField(
            controller: _keyCtrl,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key),
            ),
            obscureText: true,
            onChanged: (val) {
              // 实时保存
              provider.updateConfig(apiKey: val);
            },
          ),
          const SizedBox(height: 16),

          // 3. 模型选择 (带刷新按钮的经典布局)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '模型名称',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.model_training),
                  ),
                  initialValue: dropdownItems.isEmpty ? null : config.modelName,
                  items: dropdownItems.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      provider.updateConfig(modelName: val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 【核心回归】刷新按钮
              IconButton.filledTonal(
                onPressed: _isFetchingModels ? null : () => _fetchModelList(provider),
                icon: _isFetchingModels
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: '从服务器获取最新模型列表',
              ),
            ],
          ),

          // 4. 手动输入入口 (经典布局)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _showManualModelDialog(context, provider);
              },
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('手动输入模型名', style: TextStyle(fontSize: 12)),
            ),
          ),

          const Divider(height: 32),

          // 5. 高级设置 (BaseURL + Prompt)
          ListTile(
            title: const Text('高级设置'),
            subtitle: const Text('Base URL、系统提示词'),
            trailing: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          ),

          if (_showAdvanced || config.provider == 'custom') ...[
            TextField(
              controller: _baseUrlCtrl,
              decoration: InputDecoration(
                labelText: 'Base URL (API 地址)',
                hintText: 'https://api.openai.com/v1',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                helperText: config.provider != 'custom' ? '通常不需要修改，除非使用代理' : '必填',
              ),
              onChanged: (val) => provider.updateConfig(baseUrl: val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '自定义系统提示词 (System Prompt)',
                hintText: '覆盖默认 AI 人设，例如：你是一个严谨的科幻小说家...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => provider.updateConfig(customPrompt: val),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // 6. 测试连接按钮 (经典回归)
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isTesting ? null : () => _testConnection(provider),
              icon: const Icon(Icons.network_check),
              label: Text(_isTesting ? '测试连接中...' : '测试连接 (保存并验证)'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
