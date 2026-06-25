import 'package:flutter/services.dart';

/// 核心升级：适配富文本物理段落的自动缩进
class AutoIndentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.isCollapsed && oldValue.selection.isValid) {
      final oldStart = oldValue.selection.start;
      final newCursor = newValue.selection.baseOffset;

      if (newCursor == oldStart + 1 && newValue.text.substring(oldStart, newCursor) == '\n') {
        // 【核心修改】：去掉了多余的一个 \n！
        // 因为我们即将启用渲染层的“无级段间距”，回车只需产生一个真正的自然段，
        // 再带上两个全角空格（\u3000\u3000）作为首行缩进即可。
        String newText = newValue.text.replaceRange(oldStart, newCursor, '\n\u3000\u3000');

        return TextEditingValue(
          text: newText,
          // 光标位置：跳过 1 个换行 + 2 个全角空格（1+2 = 3）
          selection: TextSelection.collapsed(offset: oldStart + 3),
        );
      }
    }
    return newValue;
  }
}