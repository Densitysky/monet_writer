import 'package:flutter/material.dart';

/// 专为设定、大纲打造的半所见即所得 Markdown 控制器
class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String sourceText = text;
    if (sourceText.isEmpty) {
      return TextSpan(style: style, text: sourceText);
    }

    // 默认样式
    final TextStyle defaultStyle = style ?? const TextStyle();

    // Markdown 标记符号的颜色（变淡，降低视觉干扰）
    final TextStyle syntaxStyle = defaultStyle.copyWith(
      color: defaultStyle.color?.withValues(alpha: 0.3),
    );

    // 粗体样式
    final TextStyle boldStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
    );

    // 一级标题样式
    final TextStyle h1Style = defaultStyle.copyWith(
      fontSize: (defaultStyle.fontSize ?? 16) * 1.5,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );

    // 二级标题样式
    final TextStyle h2Style = defaultStyle.copyWith(
      fontSize: (defaultStyle.fontSize ?? 16) * 1.25,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );

    List<TextSpan> spans = [];

    // 正则表达式匹配：
    // 1. 一级标题: ^# (文字)
    // 2. 二级标题: ^## (文字)
    // 3. 粗体: **文字**
    final RegExp exp = RegExp(r'(^#\s+.*$)|(^##\s+.*$)|(\*\*.*?\*\*)', multiLine: true);

    int lastMatchEnd = 0;

    for (final Match match in exp.allMatches(sourceText)) {
      // 1. 添加匹配项之前的普通文本
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: sourceText.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      final String matchText = match.group(0)!;

      // 2. 解析具体的 Markdown 语法并施加样式
      if (matchText.startsWith('## ')) {
        // H2
        spans.add(TextSpan(text: '## ', style: syntaxStyle.copyWith(fontSize: h2Style.fontSize)));
        spans.add(TextSpan(text: matchText.substring(3), style: h2Style));
      } else if (matchText.startsWith('# ')) {
        // H1
        spans.add(TextSpan(text: '# ', style: syntaxStyle.copyWith(fontSize: h1Style.fontSize)));
        spans.add(TextSpan(text: matchText.substring(2), style: h1Style));
      } else if (matchText.startsWith('**') && matchText.endsWith('**')) {
        // Bold
        spans.add(TextSpan(text: '**', style: syntaxStyle));
        spans.add(TextSpan(text: matchText.substring(2, matchText.length - 2), style: boldStyle));
        spans.add(TextSpan(text: '**', style: syntaxStyle));
      } else {
        // Fallback
        spans.add(TextSpan(text: matchText, style: defaultStyle));
      }

      lastMatchEnd = match.end;
    }

    // 3. 添加最后剩下的普通文本
    if (lastMatchEnd < sourceText.length) {
      spans.add(TextSpan(
        text: sourceText.substring(lastMatchEnd, sourceText.length),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}