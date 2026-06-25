import 'package:flutter/material.dart';

/// 文本排版工具类
/// 独立于业务逻辑之外，专职负责各种文字处理
class TextFormatUtil {

  /// 一键自动排版核心逻辑 (V2.0 适配富文本排版引擎)
  static void autoFormat(TextEditingController controller, VoidCallback onFormatted) {
    final text = controller.text;
    if (text.isEmpty) return;

    // 1. 统一换行符：把 Windows 可能存在的 \r\n 全部转成标准的 \n
    final normalizedText = text.replaceAll('\r\n', '\n');
    final lines = normalizedText.split('\n');
    final formattedLines = <String>[];

    for (var line in lines) {
      // 2. 清除该行首尾的所有空白字符（包括全角/半角空格、制表符等）
      var trimmed = line.trim();

      // 再次强制剔除首部的全角空格，防止重复缩进
      trimmed = trimmed.replaceAll(RegExp(r'^[\u3000\s]+'), '');

      // 3. 如果这一行是彻底的空行，直接强行剔除！
      if (trimmed.isEmpty) continue;

      // 4. 为正常的非空段落加上标准的“两个全角空格”缩进
      formattedLines.add('\u3000\u3000$trimmed');
    }

    // 5. 【核心修复】：由于新排版引擎自带物理段间距，这里【必须】使用单换行 (\n) 拼接！
    // 这样数据最干净，且视觉上拥有完美的 32px 呼吸感间距。
    final newText = formattedLines.join('\n');

    // 6. 更新编辑器，并将光标移动到文本末尾
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    // 7. 触发回调（让底层触发脏标记，自动保存到 Isar 数据库）
    onFormatted();
  }
}