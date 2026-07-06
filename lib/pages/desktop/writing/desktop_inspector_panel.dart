import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/pages/desktop/writing/components/inspector_character_tab.dart';
import 'package:monet_writer/pages/desktop/writing/components/inspector_outline_tab.dart';
import 'package:monet_writer/pages/desktop/writing/components/inspector_format_tab.dart';

class DesktopInspectorPanel extends StatefulWidget {
  final int initialTab;
  final ValueNotifier<int>? tabController;

  final ValueNotifier<String?>? aiSelectedText;

  const DesktopInspectorPanel({
    super.key,
    this.initialTab = 0,
    this.tabController,
    this.aiSelectedText,
  });

  @override
  State<DesktopInspectorPanel> createState() => _DesktopInspectorPanelState();
}

class _DesktopInspectorPanelState extends State<DesktopInspectorPanel> {
  late int _currentTabIndex;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [
    {'isAi': true, 'text': '你好！我是 Monet AI。\n在左侧选中文字，点击上方【润色】【扩写】可生成修改建议；\n满意后点击 AI 消息下方的「替换原文」应用修改。', 'canInsert': false, 'canReplace': false},
  ];
  bool _isAiTyping = false;
  int? _replacedMessageIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    widget.tabController?.addListener(_onTabControllerChanged);
    widget.aiSelectedText?.addListener(_onAiSelectedTextChanged);
  }

  @override
  void didUpdateWidget(covariant DesktopInspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabController != oldWidget.tabController) {
      oldWidget.tabController?.removeListener(_onTabControllerChanged);
      widget.tabController?.addListener(_onTabControllerChanged);
    }
    if (widget.aiSelectedText != oldWidget.aiSelectedText) {
      oldWidget.aiSelectedText?.removeListener(_onAiSelectedTextChanged);
      widget.aiSelectedText?.addListener(_onAiSelectedTextChanged);
    }
    if (widget.initialTab != oldWidget.initialTab) {
      _currentTabIndex = widget.initialTab;
    }
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_onTabControllerChanged);
    widget.aiSelectedText?.removeListener(_onAiSelectedTextChanged);
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (widget.tabController != null) {
      setState(() => _currentTabIndex = widget.tabController!.value);
    }
  }

  String? _lastAiSelectedText;

  void _onAiSelectedTextChanged() {
    final text = widget.aiSelectedText?.value;
    if (text == null || text.isEmpty || text == _lastAiSelectedText) return;
    _lastAiSelectedText = text;

    final provider = context.read<WritingProvider>();
    final selection = provider.contentController.selection;
    _sendUserMessage(
      '请对以下文字进行文学性润色，使表达更流畅、更有感染力，保留原意：\n\n$text',
      provider,
      replaceRange: selection.isValid && !selection.isCollapsed ? selection : null,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _handleInlineAiAction(String instruction, WritingProvider provider) async {
    final selection = provider.contentController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💡 请先在左侧正文中选中需要处理的文字')));
      return;
    }

    final selectedText = selection.textInside(provider.contentController.text);
    final prompt = '请对以下文字进行$instruction，直接输出修改后的文本，不要解释：\n\n$selectedText';
    await _sendUserMessage(prompt, provider, replaceRange: selection);
  }

  Future<void> _sendUserMessage(String text, WritingProvider provider, {TextSelection? replaceRange}) async {
    if (text.trim().isEmpty || _isAiTyping) return;

    setState(() {
      _chatHistory.add({'isAi': false, 'text': text.trim(), 'canInsert': false, 'canReplace': false});
      _isAiTyping = true;
    });
    _chatController.clear();
    _scrollToBottom();

    try {
      final aiProvider = context.read<AiProvider>();
      if (aiProvider.config.apiKey.isEmpty ?? true) {
        throw Exception('请先在全局设置中配置 AI API Key');
      }

      final content = await provider.getRecentContent(limit: 2);
      final systemPrompt = replaceRange != null
          ? '你是一个专业的小说写作助手。请直接输出修改后的正文，不要输出任何解释、前缀或总结。'
          : '你是一个专业的小说写作助手。请根据用户的提问提供建设性的写作建议或灵感。必要时你可以参考以下近期的正文上下文：\n$content';

      final response = await AiService.generateText(aiProvider.config, systemPrompt: systemPrompt, userPrompt: text);

      if (mounted) {
        setState(() {
          _chatHistory.add({
            'isAi': true,
            'text': response.trim(),
            'canInsert': replaceRange == null,
            'canReplace': replaceRange != null,
            'replaceStart': replaceRange?.start,
            'replaceEnd': replaceRange?.end,
            'originalText': replaceRange?.textInside(provider.contentController.text),
            'isReplaced': false,
          });
          _isAiTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({'isAi': true, 'text': '❌ 请求失败: ${e.toString().replaceAll('Exception: ', '')}', 'canInsert': false, 'canReplace': false});
          _isAiTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _replaceSelection(String newText, int start, int end, int messageIndex) {
    final provider = context.read<WritingProvider>();
    final currentText = provider.contentController.text;
    final updatedText = currentText.replaceRange(start, end, newText);

    provider.contentController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + newText.length),
    );
    provider.onContentChanged();

    setState(() {
      _chatHistory[messageIndex]['isReplaced'] = true;
      _replacedMessageIndex = messageIndex;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已替换选中文本')));
  }

  void _undoReplace() {
    final index = _replacedMessageIndex;
    if (index == null) return;

    final msg = _chatHistory[index];
    final start = msg['replaceStart'] as int?;
    final end = msg['replaceEnd'] as int?;
    final originalText = msg['originalText'] as String?;
    final newText = msg['text'] as String?;

    if (start == null || end == null || originalText == null || newText == null) return;

    final provider = context.read<WritingProvider>();
    final currentText = provider.contentController.text;
    final newEnd = start + newText.length;
    final restoredText = currentText.replaceRange(start, newEnd, originalText);

    provider.contentController.value = TextEditingValue(
      text: restoredText,
      selection: TextSelection.collapsed(offset: start + originalText.length),
    );
    provider.onContentChanged();

    setState(() {
      _chatHistory[index]['isReplaced'] = false;
      _replacedMessageIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('↩️ 已撤销替换')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();

    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        _buildTabBar(currentTheme, primaryColor, isPaper),
        Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

        Expanded(
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              InspectorOutlineTab(currentTheme: currentTheme, isPaper: isPaper, primaryColor: primaryColor),
              InspectorCharacterTab(currentTheme: currentTheme, isPaper: isPaper, primaryColor: primaryColor),
              InspectorFormatTab(currentTheme: currentTheme, isPaper: isPaper, primaryColor: primaryColor),
              _buildAiChatView(currentTheme, isPaper, primaryColor, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(WritingTheme theme, Color primary, bool isPaper) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.textColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0),
        ),
        child: Row(
          children: [
            _buildTabButton('大纲', 0, theme, primary, isPaper),
            _buildTabButton('角色', 1, theme, primary, isPaper),
            _buildTabButton('排版', 2, theme, primary, isPaper),
            _buildTabButton('✨ AI', 3, theme, primary, isPaper),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, WritingTheme theme, Color primary, bool isPaper) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? theme.backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(isPaper ? 4.0 : 6.0),
            boxShadow: isSelected && !isPaper ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primary : theme.textColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildAiChatView(WritingTheme theme, bool isPaper, Color primary, WritingProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.textColor.withValues(alpha: 0.05), width: 1))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAiQuickAction('原位润色', CupertinoIcons.sparkles, theme, primary, isPaper, () => _handleInlineAiAction('进行文学性润色，保留原意', provider)),
                _buildAiQuickAction('扩写描写', CupertinoIcons.arrow_up_left_arrow_down_right, theme, primary, isPaper, () => _handleInlineAiAction('扩写细节描写，增加环境和心理渲染', provider)),
                _buildAiQuickAction('精简缩写', CupertinoIcons.arrow_down_right_arrow_up_left, theme, primary, isPaper, () => _handleInlineAiAction('精简多余废话，让节奏紧凑', provider)),
              ],
            ),
          ),
        ),
        if (_lastAiSelectedText != null && _lastAiSelectedText!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(isPaper ? 4.0 : 10.0),
              border: Border.all(color: primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.quote_bubble, size: 14, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '已选中文本：$_lastAiSelectedText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: primary),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatHistory.length + (_isAiTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _chatHistory.length && _isAiTyping) return _buildAiTypingIndicator(theme, primary, isPaper);
              final msg = _chatHistory[index];
              return _buildChatBubble(
                msg['text'],
                theme,
                primary,
                isPaper,
                isAi: msg['isAi'],
                canInsert: msg['canInsert'] ?? false,
                canReplace: msg['canReplace'] ?? false,
                replaceStart: msg['replaceStart'],
                replaceEnd: msg['replaceEnd'],
                originalText: msg['originalText'],
                isReplaced: msg['isReplaced'] ?? false,
                messageIndex: index,
                provider: provider,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPaper ? theme.backgroundColor : theme.textColor.withValues(alpha: 0.02),
            border: Border(top: BorderSide(color: theme.textColor.withValues(alpha: 0.05), width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
                    border: isPaper ? Border.all(color: theme.textColor.withValues(alpha: 0.1)) : null,
                  ),
                  child: TextField(
                    controller: _chatController,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(color: theme.textColor, fontSize: 13, height: 1.4),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '向 AI 提问或输入要求...',
                      hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3), fontSize: 13, height: 1.4),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (text) => _sendUserMessage(text, provider),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40, width: 40,
                decoration: BoxDecoration(color: _isAiTyping ? theme.textColor.withValues(alpha: 0.1) : primary, borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _isAiTyping
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.textColor.withValues(alpha: 0.5)))
                      : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 18),
                  onPressed: _isAiTyping ? null : () => _sendUserMessage(_chatController.text, provider),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiQuickAction(String label, IconData icon, WritingTheme theme, Color primary, bool isPaper, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: primary.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0), color: primary.withValues(alpha: 0.05)),
          child: Row(
            children: [
              Icon(icon, size: 12, color: primary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiTypingIndicator(WritingTheme theme, Color primary, bool isPaper) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
            const SizedBox(width: 8),
            Text('AI 正在思考...', style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    String text,
    WritingTheme theme,
    Color primary,
    bool isPaper, {
    required bool isAi,
    required bool canInsert,
    required bool canReplace,
    int? replaceStart,
    int? replaceEnd,
    String? originalText,
    required bool isReplaced,
    required int messageIndex,
    required WritingProvider provider,
  }) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: isAi ? 0 : 32, right: isAi ? 32 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAi ? theme.textColor.withValues(alpha: 0.05) : primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(isPaper ? 4.0 : 12.0), topRight: Radius.circular(isPaper ? 4.0 : 12.0), bottomLeft: Radius.circular(isPaper ? 4.0 : (isAi ? 2.0 : 12.0)), bottomRight: Radius.circular(isPaper ? 4.0 : (isAi ? 12.0 : 2.0))),
          border: isPaper ? Border.all(color: isAi ? theme.textColor.withValues(alpha: 0.1) : primary.withValues(alpha: 0.2)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: isAi ? theme.textColor.withValues(alpha: 0.9) : primary, fontSize: 13, height: 1.5)),
            if (isAi && canInsert) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  provider.insertText(text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已插入到正文')));
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.checkmark_rectangle, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text('插入到正文光标处', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
            if (isAi && canReplace && replaceStart != null && replaceEnd != null) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              if (!isReplaced)
                InkWell(
                  onTap: () => _replaceSelection(text, replaceStart, replaceEnd, messageIndex),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_right_arrow_left, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text('替换原文', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('已替换', style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.4))),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _undoReplace,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.restart, size: 14, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text('撤销', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ]
          ],
        ),
      ),
    );
  }
}

