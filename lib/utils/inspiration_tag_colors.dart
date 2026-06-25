import 'package:flutter/material.dart';

/// 灵感碎片标签配色映射 — 移动端与桌面端共享
/// 返回 (背景色, 文字色)
(Color, Color) getInspirationTagColor(String tag) {
  switch (tag) {
    case '角色':
      return (const Color(0xFFE6F1FB), const Color(0xFF185FA5));
    case '情节':
      return (const Color(0xFFE6F1FB), const Color(0xFF185FA5));
    case '场景':
      return (const Color(0xFFFBEAF0), const Color(0xFF993556));
    case '金句':
      return (const Color(0xFFE1F5EE), const Color(0xFF0F6E56));
    case '世界观':
      return (const Color(0xFFFAEEDA), const Color(0xFFBA7517));
    default:
      return (const Color(0xFFF1EFE8), const Color(0xFF5F5E5A));
  }
}
