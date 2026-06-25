import 'package:flutter/material.dart';
import 'package:monet_writer/models/prompt_template.dart';
import 'package:monet_writer/services/prompt_manager.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class AiPromptsPage extends StatelessWidget {
  const AiPromptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 提示词配置')),
      body: ListView(
        children: [
          _buildSectionHeader(context, '角色相关'),
          _buildItem(
            context,
            PromptManager.SCENE_CHAR_ANALYSIS,
            '角色深度分析',
            '用于角色详情页的时间轴与生平同步',
            Icons.person_search,
          ),
          _buildItem(
            context,
            PromptManager.SCENE_CHAR_Extract,
            '章节角色提取',
            '用于角色列表页的批量提取功能',
            Icons.people_alt,
          ),
          const Divider(),
          _buildSectionHeader(context, '大纲相关'),
          _buildItem(
            context,
            PromptManager.SCENE_OUTLINE_NODE,
            '章节细纲生成',
            '根据当前章节生成剧情节点',
            Icons.segment,
          ),
          _buildItem(
            context,
            PromptManager.SCENE_WORLD_SETTING,
            '设定/世界观补全',
            '根据正文自动补充设定文档',
            Icons.auto_fix_high,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildItem(BuildContext context, String code, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MonetPageRoute(builder: (_) => PromptEditorPage(sceneCode: code, title: title)),
        );
      },
    );
  }
}

class PromptEditorPage extends StatefulWidget {
  final String sceneCode;
  final String title;

  const PromptEditorPage({super.key, required this.sceneCode, required this.title});

  @override
  State<PromptEditorPage> createState() => _PromptEditorPageState();
}

class _PromptEditorPageState extends State<PromptEditorPage> {
  PromptTemplate? _template;
  bool _isLoading = true;

  final _simpleCtrl = TextEditingController();
  final _advancedCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final t = await PromptManager.getTemplate(widget.sceneCode);
    setState(() {
      _template = t;
      _simpleCtrl.text = t.userCustomPreference ?? '';
      _advancedCtrl.text = t.fullOverride ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _simpleCtrl.dispose();
    _advancedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isAdvanced = _template!.isAdvancedMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(context),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('高级开发者模式'),
            subtitle: const Text('开启后可编辑完整的 System Prompt，但需自行保证 JSON 格式正确。'),
            value: isAdvanced,
            onChanged: (val) async {
              await PromptManager.toggleAdvancedMode(widget.sceneCode, val);
              _loadData();
            },
          ),
          const Divider(),

          if (!isAdvanced) ...[
            _buildSectionTitle('自定义偏好 (简单模式)'),
            const SizedBox(height: 8),
            const Text('在此输入您希望 AI 注意的细节。AI 会自动将其插入到标准指令中。', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _simpleCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例如：请重点关注剧情转折，忽略环境描写...',
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text('查看完整指令预览', style: TextStyle(fontSize: 14)),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: Text(
                    "${_template!.baseSystemPrompt}\n\n[用户偏好]: ${_simpleCtrl.text}\n\n${_template!.formatConstraint}",
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                )
              ],
            )
          ] else ...[
            _buildSectionTitle('完整 System Prompt (高级模式)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('警告：如果该场景需要返回 JSON，请务必在指令中保留 JSON 格式定义！', style: TextStyle(color: Colors.orange, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _advancedCtrl,
              maxLines: null,
              minLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入完整的 System Prompt...',
                filled: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (_template!.isAdvancedMode) {
      await PromptManager.updateFullOverride(widget.sceneCode, _advancedCtrl.text);
    } else {
      await PromptManager.updateUserPreference(widget.sceneCode, _simpleCtrl.text);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      Navigator.pop(context);
    }
  }
}
