import 'dart:math';
import 'package:flutter/material.dart';

class ColorGenerator {
  /// 预设的一组低饱和度、高明度的马卡龙色系，适合做无封面时的默认占位背景
  static const List<Color> _bgColors = [
    Color(0xFFE8F5E9), // 浅绿
    Color(0xFFE3F2FD), // 浅蓝
    Color(0xFFF3E5F5), // 浅紫
    Color(0xFFFFF3E0), // 浅橙
    Color(0xFFFFEBEE), // 浅红
    Color(0xFFE0F7FA), // 青色
    Color(0xFFFFF8E1), // 浅黄
    Color(0xFFF1F8E9), // 嫩绿
  ];

  /// 根据字符串(如书名)生成固定的背景色
  static Color generateBgColor(String input) {
    if (input.isEmpty) return _bgColors[0];
    final int hash = input.hashCode;
    final int index = hash.abs() % _bgColors.length;
    return _bgColors[index];
  }

  /// 【核心升级】：符合 WCAG 4.5:1 无障碍标准的智能文字颜色计算
  /// 根据背景色的亮度 (Luminance)，智能返回黑色或白色
  static Color getWcagTextColor(Color backgroundColor) {
    // 0.5 是中性灰的视觉亮度边界。
    // 大于 0.5 说明背景偏亮，必须用深色字；小于 0.5 说明背景偏暗，必须用浅色字。
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  /// (保留向后兼容) 如果非要同色系深色，也必须经过 WCAG 校验保护
  static Color getTextColor(Color bgColor) {
    final textColor = HSLColor.fromColor(bgColor).withLightness(0.3).toColor();
    // 如果算出来的同色系深色在当前背景上对比度太低，强制走 WCAG 保护机制
    if (bgColor.computeLuminance() < 0.5) {
      return Colors.white;
    }
    return textColor;
  }
}