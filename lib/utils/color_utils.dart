import 'package:flutter/material.dart';

/// 根据背景色明度返回合适的文字色（白底黑字 / 黑底白字）
Color contrastTextColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5
      ? const Color(0xFF1C1C1A)  // 深色文字
      : const Color(0xFFFAFAF8); // 浅色文字
}

/// 计算与背景色形成最佳对比的文字色（纯白或纯黑）
Color getWcagTextColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.179
      ? Colors.black
      : Colors.white;
}
