import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

/// 高频 Provider 读取优化扩展
/// 使用 context.select 替代 context.watch，仅在特定属性变化时重建

extension BuildContextSelectX on BuildContext {
  /// 仅 isFlat 变化时重建
  bool get selectIsFlat =>
      select<ThemeProvider, bool>((p) => p.themeStyle == AppThemeStyle.flat);

  /// 仅当前主题变化时重建
  WritingTheme get selectCurrentTheme =>
      select<UserProvider, WritingTheme>((u) => u.currentTheme);

  /// 仅种子色变化时重建
  Color get selectSeedColor =>
      select<ThemeProvider, Color>((p) => p.seedColor);
}
