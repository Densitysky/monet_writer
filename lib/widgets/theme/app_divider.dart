import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';

/// 主题感知分割线。
/// 柔和模式下更轻，纸感模式下更硬。
class AppDivider extends StatelessWidget {
  final double height;

  const AppDivider({super.key, this.height = 1});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<ThemeProvider>().themeStyle;
    final cs = Theme.of(context).colorScheme;

    final color = switch (style) {
      AppThemeStyle.neumorphic => cs.outlineVariant,
      AppThemeStyle.paper  => cs.outlineVariant,
      _ => cs.outlineVariant,
    };

    return Divider(height: height, color: color);
  }
}
