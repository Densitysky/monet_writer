import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

/// 主题感知卡片组件。
///
/// | 风格   | 外观                         |
/// |--------|------------------------------|
/// | modern | Material Card (elevated)     |
/// | paper  | 纸感：米白底 + 细线边框 + 8px圆角 |
/// | golden | 温白底 + 无投影 + 12px圆角     |
/// | neumorphic | 白底 + neumorphic双阴影 + 16px |
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.margin, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<ThemeProvider>().themeStyle;
    final isPaper = style == AppThemeStyle.paper;

    Widget card = switch (style) {
      AppThemeStyle.modern => _modernCard(context),
      AppThemeStyle.paper || AppThemeStyle.parchment => _paperCard(context),
      AppThemeStyle.golden => _goldenCard(context),
      AppThemeStyle.neumorphic => _neumorphicCard(context, isPaper),
    };

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: style == AppThemeStyle.paper
            ? BorderRadius.circular(8)
            : style == AppThemeStyle.neumorphic
                ? BorderRadius.circular(16)
                : BorderRadius.circular(12),
        child: card,
      );
    }

    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }

  Widget _modernCard(BuildContext context) {
    return Card(child: padding != null ? Padding(padding: padding!, child: child) : child);
  }

  Widget _paperCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _goldenCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 60:30:10 — 30% 层用 secondaryContainer 做卡片底色
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _neumorphicCard(BuildContext context, bool isPaper) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 参考图同款 Soft UI：卡片略亮于背景，阴影负责"轻抬"而非重浮雕
    // 高 blur/offset 比（约 4:1）+ 冷灰蓝柔影 = 网页风轻柔质感
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? const [
                BoxShadow(color: Color(0xFF48484A), offset: Offset(-4, -4), blurRadius: 12, spreadRadius: 0),
                BoxShadow(color: Color(0xFF0A0A0B), offset: Offset(6, 6), blurRadius: 16, spreadRadius: 0),
              ]
            : const [
                // 左上高光：纯白，大模糊半径模拟柔和受光
                BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 20, spreadRadius: 0),
                // 右下阴影：冷灰蓝 #C5CEDC，与背景 #EDF0F4 形成轻柔对比
                BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(6, 6), blurRadius: 24, spreadRadius: 0),
              ],
      ),
      child: child,
    );
  }
}
