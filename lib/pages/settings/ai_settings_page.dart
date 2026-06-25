import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/services/ai_service.dart';
// 【关键修复】引入模型定义
import 'package:monet_writer/models/ai/ai_config.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final _keyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();

  bool _isTesting = false;
  bool _isFetchingModels = false;
  bool _showAdvanced = false; // 是否展开高级设置(Base URL)

  @override
  void initState() {
    super.initState();
    final config = context.read<AiProvider>().config;
    _keyCtrl.text = config.apiKey;
    _baseUrlCtrl.text = config.baseUrl ?? '';
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  // 测试生成
  Future<void> _testConnection(AiProvider provider) async {
    setState(() => _isTesting = true);
    try {
      final response = await AiService.generateText(
        provider.config,
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: 'Reply "Connection OK" if you receive this.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功: $response'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  // 动态拉取模型列表
  Future<void> _fetchModelList(AiProvider provider) async {
    if (_keyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }

    setState(() => _isFetchingModels = true);
    try {
      // 临时构建一个 config 对象用于请求
      final tempConfig = AiConfig()
        ..provider = provider.config.provider
        ..apiKey = _keyCtrl.text
        ..baseUrl = _baseUrlCtrl.text;

      final models = await AiService.fetchModels(tempConfig);

      if (mounted) {
        provider.updateModelList(models);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功获取 ${models.length} 个模型'), backgroundColor: Colors.green),
        );
        // 如果当前模型不在列表里，默认选第一个
        if (!models.contains(provider.config.modelName) && models.isNotEmpty) {
          provider.updateConfig(modelName: models.first);
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog('获取模型列表失败: $e');
    } finally {
      if (mounted) setState(() => _isFetchingModels = false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('出错'),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();
    final config = provider.config;
    final modelList = provider.currentModelList;

    // 确保当前选中的模型在列表里，否则加进去（避免 Dropdown 报错）
    final dropdownItems = List<String>.from(modelList);
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
              DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
              DropdownMenuItem(value: 'siliconflow', child: Text('硅基流动 (SiliconFlow)')),
              DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek 官方')),
              DropdownMenuItem(value: 'custom', child: Text('自定义 (OpenAI 格式)')),
            ],
            onChanged: (val) {
              if (val != null) {
                provider.updateConfig(provider: val);
                // 切换厂商后，BaseURL 也会变，刷新输入框 (从 Model 获取)
                _baseUrlCtrl.text = provider.config.baseUrl ?? '';
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
            onChanged: (val) => provider.updateConfig(apiKey: val),
          ),
          const SizedBox(height: 16),

          // 3. 模型选择 (带刷新按钮)
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
                    if (val != null) provider.updateConfig(modelName: val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _isFetchingModels ? null : () => _fetchModelList(provider),
                icon: _isFetchingModels
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: '从服务器获取最新模型列表',
              ),
            ],
          ),

          // 4. 手动输入模型入口 (兜底)
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

          // 5. 高级设置 (Base URL)
          ListTile(
            title: const Text('高级设置'),
            trailing: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          ),

          if (_showAdvanced || config.provider == 'custom')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
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
            ),

          const SizedBox(height: 24),

          // 6. 测试连接
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isTesting ? null : () => _testConnection(provider),
              icon: const Icon(Icons.network_check),
              label: Text(_isTesting ? '测试连接中...' : '测试连接'),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualModelDialog(BuildContext context, AiProvider provider) {
    final ctrl = TextEditingController(text: provider.config.modelName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入模型名'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '例如: gpt-4o'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                provider.updateConfig(modelName: ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
