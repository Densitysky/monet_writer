import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/models/ai/ai_config.dart';
import 'package:monet_writer/services/ai_service.dart';
import 'package:monet_writer/services/database_service.dart';

/// 灵感助手面板 — 右侧滑出的 AI 对话面板
class InspirationPanel extends StatefulWidget {
  final String? selectedText;
  final int? selectedStart;
  final int? selectedEnd;
  final VoidCallback onClose;
  final void Function(String text, int start, int end) onReplaceText;
  final VoidCallback onUndoReplace;
  final VoidCallback onTextCleared;

  const InspirationPanel({
    super.key,
    this.selectedText,
    this.selectedStart,
    this.selectedEnd,
    required this.onClose,
    required this.onReplaceText,
    required this.onUndoReplace,
    required this.onTextCleared,
  });

  @override
  State<InspirationPanel> createState() => _InspirationPanelState();
}

class _ChatMessage {
  final String role; // 'user' | 'ai'
  final String content;
  final bool isPending; // 等待中

  const _ChatMessage({required this.role, required this.content, this.isPending = false});
}

class _InspirationPanelState extends State<InspirationPanel> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  int? _replacedMessageIndex; // 哪个 AI 消息被替换了

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<AiConfig> _getConfig() async {
    final db = DatabaseService();
    final configs = await db.getAllAiConfigs();
    if (configs.isEmpty) throw Exception('未找到可用的 AI 配置，请先在设置中添加模型。');
    return configs.first;
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userText = text.trim();
    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: userText));
      _messages.add(_ChatMessage(role: 'ai', content: '', isPending: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final config = await _getConfig();

      List<Map<String, String>> history = [];
      // 如果有选中的文本，作为上下文
      if (widget.selectedText != null) {
        history.add({'role': 'user', 'content': '我正在编辑以下原文，请基于此回答：\n\n${widget.selectedText}'});
        history.add({'role': 'assistant', 'content': '好的，请提出你的需求。'});
      }
      // 添加历史消息（跳过 pending 的）
      for (final msg in _messages) {
        if (msg.isPending) continue;
        history.add({'role': msg.role == 'user' ? 'user' : 'assistant', 'content': msg.content});
      }

      final response = await AiService.generateText(
        config,
        systemPrompt: '你是一个专业的小说写作助手。回答要简洁有料，如果涉及修改建议，直接给出修改后的文本。',
        userPrompt: _buildPrompt(userText, history),
      );

      if (mounted) {
        setState(() {
          _messages.removeLast(); // 移除 pending
          _messages.add(_ChatMessage(role: 'ai', content: response.trim()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(_ChatMessage(role: 'ai', content: '请求失败：$e'));
          _isLoading = false;
        });
      }
    }
  }

  String _buildPrompt(String userText, List<Map<String, String>> history) {
    // 如果有选中文本且首条 AI 消息刚生成
    if (widget.selectedText != null && _messages.length <= 2) {
      return '基于以下原文：\n"""\n${widget.selectedText}\n"""\n\n请回答：$userText';
    }
    return userText;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _onReplace(String newText) {
    if (widget.selectedStart == null || widget.selectedEnd == null) return;

    widget.onReplaceText(newText, widget.selectedStart!, widget.selectedEnd!);

    setState(() {
      _replacedMessageIndex = _messages.length - 1;
    });
  }

  void _onUndo() {
    if (_replacedMessageIndex == null) return;
    widget.onUndoReplace();

    setState(() {
      _replacedMessageIndex = null;
    });
  }

  /// 润色：自动填入对话
  void _onPolish() {
    if (widget.selectedText == null) return;
    _send('请润色这段文字，让表达更流畅、更有感染力，保留原意：\n\n${widget.selectedText}');
  }

  /// 一键替换原文（直接替换选中的文本）
  void _onQuickReplace() {
    if (widget.selectedStart == null || widget.selectedEnd == null) return;
    _send('请对这段原文进行润色优化，使表达更精炼、更有文学性，直接输出修改后的文本，不要解释：\n\n${widget.selectedText!}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;
    final isPaper = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.paper;
    final txtColor = theme.textColor;
    final bgColor = theme.backgroundColor;
    final accent = Theme.of(context).colorScheme.primary;

    final hasSelection = widget.selectedText != null && widget.selectedText!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: txtColor.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: txtColor.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Text('灵感助手', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txtColor)),
                const Spacer(),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: txtColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(CupertinoIcons.xmark, size: 14, color: txtColor.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),

          // 选中文本上下文 banner
          if (hasSelection)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('📌', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.selectedText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: accent.withValues(alpha: 0.8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _CtxButton(label: '润色', onTap: _onPolish),
                  const SizedBox(width: 4),
                  _CtxButton(label: '替换', onTap: _onQuickReplace),
                ],
              ),
            ),

          // 对话列表
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg.role == 'ai';
                final canReplace = isAi && !msg.isPending && hasSelection && widget.selectedStart != null;
                final isReplaced = isAi && _replacedMessageIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isAi
                              ? (isPaper ? txtColor.withValues(alpha: 0.04) : txtColor.withValues(alpha: 0.03))
                              : accent,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isAi ? 4 : 14),
                            bottomRight: Radius.circular(isAi ? 14 : 4),
                          ),
                        ),
                        child: msg.isPending
                            ? SizedBox(
                                width: 24, height: 16,
                                child: Center(
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: txtColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: isAi ? txtColor : Colors.white,
                                ),
                              ),
                      ),

                      // AI 消息操作按钮
                      if (isAi && !msg.isPending && canReplace)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isReplaced) ...[
                                Text('已替换', style: TextStyle(fontSize: 10, color: txtColor.withValues(alpha: 0.4))),
                                const SizedBox(width: 4),
                                _ActionBtn(label: '撤销', color: const Color(0xFFD97706), onTap: _onUndo),
                              ] else ...[
                                _ActionBtn(label: '追问', color: accent, onTap: () => _inputCtrl.text = ''),
                                const SizedBox(width: 4),
                                _ActionBtn(label: '替换原文', color: const Color(0xFFD97706), onTap: () => _onReplace(msg.content)),
                                const SizedBox(width: 4),
                                                _ActionBtn(label: '复制', color: txtColor.withValues(alpha: 0.4), onTap: () {
                                                  Clipboard.setData(ClipboardData(text: msg.content));
                                                }),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 输入框
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: txtColor.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: txtColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !_isLoading,
                      style: TextStyle(fontSize: 13, color: txtColor),
                      decoration: InputDecoration(
                        hintText: '和灵感助手聊聊...',
                        hintStyle: TextStyle(fontSize: 13, color: txtColor.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: txtColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.arrow_up, size: 16, color: Colors.white),
                    onPressed: _isLoading ? null : () => _send(_inputCtrl.text),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 上下文 banner 中的小按钮
class _CtxButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtxButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
      ),
    );
  }
}

/// 消息底部的操作按钮
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

