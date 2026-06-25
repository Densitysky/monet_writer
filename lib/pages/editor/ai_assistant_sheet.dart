import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/services/ai_service.dart';

class AiAssistantSheet extends StatefulWidget {
  final String contextSummary; // 传入当前章节内容作为上下文
  final Function(String) onResult; // 回调：把 AI 写好的字传回编辑器

  const AiAssistantSheet({
    super.key,
    required this.contextSummary,
    required this.onResult,
  });

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String _resultText = '';

  // 快捷指令
  final List<String> _quickActions = ['续写一段', '润色文笔', '环境描写', '动作描写'];

  Future<void> _generate(String action) async {
    setState(() {
      _isLoading = true;
      _resultText = '';
    });

    try {
      final aiProvider = context.read<AiProvider>();

      // 截取末尾 800 字作为上下文，防止 Token 爆炸
      final contextText = widget.contextSummary.length > 800
          ? widget.contextSummary.substring(widget.contextSummary.length - 800)
          : widget.contextSummary;

      String systemPrompt = '你是一个专业的网文写作助手。请根据用户提供的上下文续写或润色内容。只返回生成的小说正文，不要包含"好的"、"如下"等废话。';
      String userPrompt = '【上下文片段】：\n...$contextText\n\n【任务】：$action';

      if (_promptController.text.isNotEmpty) {
        userPrompt += '\n【额外要求】：${_promptController.text}';
      }

      final result = await AiService.generateText(
        aiProvider.config,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      if (mounted) {
        setState(() {
          _resultText = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultText = '生成失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI 写作助手', style: theme.textTheme.titleLarge),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),

          // 快捷指令
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickActions.map((action) => ActionChip(
              label: Text(action),
              onPressed: _isLoading ? null : () => _generate(action),
              avatar: const Icon(Icons.auto_awesome, size: 16),
            )).toList(),
          ),

          const SizedBox(height: 16),

          // 自定义输入
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: '自定义要求 (可选)',
              hintText: '例如：写得更悲伤一点...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 16),

          // 结果展示区
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _resultText.isEmpty
                  ? Center(child: Text('点击上方按钮开始生成', style: TextStyle(color: theme.colorScheme.outline)))
                  : SingleChildScrollView(child: Text(_resultText, style: const TextStyle(fontSize: 16, height: 1.6))),
            ),
          ),

          const SizedBox(height: 16),

          // 采用按钮
          if (_resultText.isNotEmpty && !_isLoading)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  widget.onResult(_resultText); // 传回编辑器
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('插入到光标位置'),
              ),
            ),
        ],
      ),
    );
  }
}
