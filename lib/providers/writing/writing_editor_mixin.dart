part of '../writing_provider.dart';

/// 零件一：编辑器核心控制、AI 交互与智能符号引擎
mixin WritingEditorMixin on WritingProviderBase {

  @override
  void _handleTextChanges() {
    if (!_isAiUpdating) {
      // 1. 清理临时高亮
      contentController.clearTemporaryHighlight();

      // 2. 触发符号全量检测引擎
      _detectManualSymbolInput();

      // 3. 【核心修复】：触发自动保存计时器！
      // 只要富文本引擎抛出任何内容变化事件，就会无缝通知 Provider 进行脏标记和倒计时保存
      onContentChanged();
    }
  }

  @override
  void _detectManualSymbolInput() {
    final currentText = contentController.text;
    final selection = contentController.selection;

    if (currentText.length == _lastText.length + 1 && selection.isCollapsed) {
      final int index = selection.baseOffset - 1;
      if (index >= 0 && index < currentText.length) {
        final String char = currentText[index];
        // 自动首行缩进：换行后对新段落应用 2em 缩进
        if (char == '\n' && index + 1 < currentText.length) {
          _applyFirstLineIndent(index + 1);
        }
        const targetSymbols = "，。！？；： “”「」【】（）—…《》、";
        if (targetSymbols.contains(char)) {
          _updateRecentSymbols(char);
        }
      }
    }
    _lastText = currentText;
  }

  void _applyFirstLineIndent(int charIndex) {
    if (charIndex <= 1) return;
    _isAiUpdating = true;
    try {
      contentController.quillController.replaceText(charIndex, 0, '\u3000\u3000', null);
    } catch (_) {}
    _isAiUpdating = false;
  }

  /// 更新最近符号列表 (LRU 算法：最新使用的放最前面)
  void _updateRecentSymbols(String symbol) {
    if (recentSymbols.contains(symbol)) {
      recentSymbols.remove(symbol);
    }
    recentSymbols.insert(0, symbol);
    if (recentSymbols.length > 12) {
      recentSymbols = recentSymbols.sublist(0, 12);
    }
    notifyListeners();
  }

  /// 供工具栏调用的方法：插入符号并记录
  void recordAndInsertSymbol(String symbol, int offset) {
    insertSymbol(symbol, offset);
    _updateRecentSymbols(symbol);
  }

  // 沉浸式模式开关
  void toggleTypewriterMode() {
    isTypewriterMode = !isTypewriterMode;
    notifyListeners();
  }

  void clearAiHighlight() {
    contentController.clearTemporaryHighlight();
  }

  void prepareAiMode() {
    cachedAiSelection = contentController.selection;
  }

  // ==================== 编辑器辅助方法 ====================

  void selectCurrentParagraph() {
    final text = contentController.text;
    final selection = contentController.selection;
    if (!selection.isValid) return;

    int start = text.lastIndexOf('\n', selection.start > 0 ? selection.start - 1 : 0);
    int end = text.indexOf('\n', selection.end);

    start = (start == -1) ? 0 : start + 1;
    if (end == -1) end = text.length;

    if (start <= end) {
      contentController.selection = TextSelection(baseOffset: start, extentOffset: end);
    }
    notifyListeners();
  }

  void insertText(String textToInsert) {
    final text = contentController.text;
    final selection = contentController.selection;
    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, textToInsert);
    contentController.text = newText;
    contentController.selection = TextSelection.collapsed(offset: start + textToInsert.length);
    onContentChanged();
  }

  // 【核心升级】智能标点符号包裹逻辑
  @override
  void insertSymbol(String symbol, int offset) {
    final text = contentController.text;
    final selection = contentController.selection;
    if (!selection.isValid) return;

    if (selection.isCollapsed) {
      // 场景 A：没有选中文本 (正常打字输入) -> 插入符号，光标根据 offset 偏移(如停在引号中间)
      final start = selection.start;
      final newText = text.replaceRange(start, start, symbol);
      contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + symbol.length + offset),
      );
    } else {
      // 场景 B：有选中文本 (后期修饰) -> 智能包裹该文本
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);

      String prefix = symbol;
      String suffix = "";
      // 识别成对符号并拆分
      if (symbol.length == 2 && ['“”', '「」', '【】', '（）', '《》'].contains(symbol)) {
        prefix = symbol[0];
        suffix = symbol[1];
      }

      final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
      // 光标移动到包裹后的最末尾
      contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length + suffix.length),
      );
    }
    onContentChanged();
  }

  void moveCursor(int offset) {
    final selection = contentController.selection;
    if (!selection.isValid) return;
    int newOffset = (selection.baseOffset + offset).clamp(0, contentController.text.length);
    contentController.selection = TextSelection.collapsed(offset: newOffset);
  }

  // ==================== AI 交互逻辑 ====================

  Future<void> replaceSelectionWithAi(AiConfig config, String instruction) async {
    final selection = cachedAiSelection ?? contentController.selection;
    cachedAiSelection = null;
    if (!selection.isValid || selection.isCollapsed) return;

    final start = selection.start;
    final end = selection.end;
    final selectedText = selection.textInside(contentController.text);

    contentController.setTemporaryHighlight(start, end, Colors.purpleAccent.withValues(alpha: 0.2));
    _isAiUpdating = true;

    try {
      const systemPrompt = "你是一个专业的小说写作助手。直接输出修改后的正文，不要输出任何解释。";
      final userPrompt = "原文：\n\"$selectedText\"\n\n指令：\n\"$instruction\"";

      final response = await AiService.generateText(config, systemPrompt: systemPrompt, userPrompt: userPrompt);

      String newText = response.trim().replaceAll(RegExp(r'^```.*$', multiLine: true), '').trim();
      if (newText.isEmpty) throw Exception("AI 返回内容为空");

      final currentText = contentController.text;
      final newFullText = currentText.replaceRange(start, end, newText);
      final newEnd = start + newText.length;

      contentController.value = TextEditingValue(
        text: newFullText,
        selection: TextSelection.collapsed(offset: newEnd),
      );

      contentController.setTemporaryHighlight(start, newEnd, Colors.greenAccent.withValues(alpha: 0.3));
      onContentChanged();
    } catch (e) {
      debugPrint("AI 请求失败: $e");
      contentController.clearTemporaryHighlight();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => _isAiUpdating = false);
    }
  }
}