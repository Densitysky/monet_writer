import 'package:flutter/material.dart';

class HighlightTextEditingController extends TextEditingController {
  // --- 临时高亮相关（用于 AI 生成反馈） ---
  TextRange? _tempHighlightRange;
  Color? _tempHighlightColor;

  // --- 关键词高亮相关 ---
  Set<String> _keywords = {};

  // 设置临时高亮（例如：紫色锁定区 或 绿色结果区）
  void setTemporaryHighlight(int start, int end, Color color) {
    if (start >= end) return;
    _tempHighlightRange = TextRange(start: start, end: end);
    _tempHighlightColor = color;
    notifyListeners(); // 触发重绘
  }

  // 清除临时高亮
  void clearTemporaryHighlight() {
    if (_tempHighlightRange != null) {
      _tempHighlightRange = null;
      _tempHighlightColor = null;
      notifyListeners();
    }
  }

  // 更新关键词
  void updateKeywords(Set<String> newKeywords) {
    _keywords = newKeywords;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 1. 如果没有任何高亮需求，直接返回普通文本，保持最高渲染性能
    if ((_tempHighlightRange == null) && _keywords.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final List<TextSpan> children = [];
    final String text = this.text;
    int currentIndex = 0;

    // 2. 处理临时背景高亮
    if (_tempHighlightRange != null) {
      final int start = _tempHighlightRange!.start.clamp(0, text.length);
      final int end = _tempHighlightRange!.end.clamp(0, text.length);

      // 第一段：高亮前的文本
      if (start > currentIndex) {
        children.add(_buildKeywordSpan(text.substring(currentIndex, start), style));
      }

      // 第二段：高亮文本 (应用背景色)
      if (end > start) {
        children.add(TextSpan(
          text: text.substring(start, end),
          style: style?.copyWith(backgroundColor: _tempHighlightColor),
        ));
      }

      currentIndex = end;
    }

    // 第三段：剩余文本
    if (currentIndex < text.length) {
      children.add(_buildKeywordSpan(text.substring(currentIndex), style));
    }

    return TextSpan(style: style, children: children);
  }

  // 辅助方法：处理角色名字的关键词高亮
  TextSpan _buildKeywordSpan(String textSegment, TextStyle? style) {
    if (_keywords.isEmpty) return TextSpan(text: textSegment, style: style);

    final List<TextSpan> spans = [];
    final pattern = RegExp(_keywords.map(RegExp.escape).join('|'));

    textSegment.splitMapJoin(
      pattern,
      onMatch: (m) {
        spans.add(TextSpan(
          text: m[0],
          style: style?.copyWith(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ));
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n, style: style));
        return '';
      },
    );

    return TextSpan(children: spans);
  }
}