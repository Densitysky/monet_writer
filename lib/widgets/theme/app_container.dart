import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

/// 页面级背景容器。
/// 柔和用 Soft UI 灰底 `#EBECED`，纸感用 Material 白，其余用 WritingTheme。
class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final style = themeProvider.themeStyle;
    final currentTheme = userProvider.currentTheme;

    Color bg;
    switch (style) {
      case AppThemeStyle.neumorphic:
        bg = Theme.of(context).scaffoldBackgroundColor;
        break;
      case AppThemeStyle.paper:
        bg = Theme.of(context).scaffoldBackgroundColor;
        break;
      default:
        bg = currentTheme.backgroundColor;
    }

    return Container(
      color: bg,
      padding: padding,
      child: child,
    );
  }
}
