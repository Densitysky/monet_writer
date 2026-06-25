import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'auto_format_tile.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class RootView extends StatelessWidget {
  final Function(String key, String title) onNavigate;

  const RootView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<UserProvider>().currentTheme;

    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;
    final double cardRadius = isFlat ? 4.0 : 12.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildItem(
          context,
          index: 0,
          icon: Icons.account_circle_outlined,
          title: '角色卡片',
          onTap: () => onNavigate('character', '角色卡片'),
          currentTheme: currentTheme,
          cardRadius: cardRadius,
        ),
        _buildItem(
          context,
          index: 1,
          icon: Icons.auto_stories_outlined,
          title: '大纲梳理',
          onTap: () => onNavigate('outline', '大纲梳理'),
          currentTheme: currentTheme,
          cardRadius: cardRadius,
        ),
        _buildItem(
          context,
          index: 2,
          icon: Icons.format_size,
          title: '排版设置',
          onTap: () => onNavigate('settings', '排版设置'),
          currentTheme: currentTheme,
          cardRadius: cardRadius,
        ),

        FadeSlideEntrance(
          delayMs: 300,
          child: Card(
            elevation: 0,
            color: currentTheme.textColor.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 12),
            // 【已修改】无论是现代风还是极简风，统统不要线框，靠底色区分层级
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
              side: BorderSide.none,
            ),
            child: const AutoFormatTile(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
      BuildContext context, {
        required int index,
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        required WritingTheme currentTheme,
        required double cardRadius,
      }) {
    final theme = Theme.of(context);
    return FadeSlideEntrance(
      delayMs: index * 100,
      child: BouncingWidget(
        onTap: onTap,
        scaleFactor: 0.95,
        child: Card(
          elevation: 0,
          color: currentTheme.textColor.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          // 【已修改】无论是现代风还是极简风，统统不要线框
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor)),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: currentTheme.textColor.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}