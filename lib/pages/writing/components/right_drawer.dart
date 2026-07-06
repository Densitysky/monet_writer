import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入主题引擎
import 'right_drawer_views/root_view.dart';
import 'right_drawer_views/outline_view.dart';
import 'right_drawer_views/settings_view.dart';
import 'right_drawer_views/character_view.dart';

enum MenuLevel { root, outline, character, settings }

class RightDrawer extends StatefulWidget {
  final int? initialIndex;

  const RightDrawer({super.key, this.initialIndex});

  @override
  State<RightDrawer> createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  MenuLevel _currentLevel = MenuLevel.root;
  String _title = '工具箱';

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _handleInitialIndex(widget.initialIndex!);
    }
  }

  void _handleInitialIndex(int index) {
    switch (index) {
      case 0:
        _currentLevel = MenuLevel.outline;
        _title = '大纲管理';
        break;
      case 1:
        _currentLevel = MenuLevel.character;
        _title = '角色管理';
        break;
      default:
        _currentLevel = MenuLevel.root;
        _title = '工具箱';
    }
  }

  void _navigateTo(MenuLevel level, String title) {
    setState(() {
      _currentLevel = level;
      _title = title;
    });
  }

  void _navigateBack() {
    setState(() {
      _currentLevel = MenuLevel.root;
      _title = '工具箱';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final currentTheme = userProvider.currentTheme;

    // 【核心】动态获取视觉风格
    final isPaper = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.paper;
    final double radius = isPaper ? 4.0 : 24.0; // 【动态圆角】

    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = currentTheme.backgroundColor.computeLuminance() < 0.5;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: EdgeInsets.only(top: topPadding + 10, bottom: 40, right: 10, left: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), // 【动态圆角】
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: currentTheme.backgroundColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(radius), // 【动态圆角】
                boxShadow: [
                  if (!isPaper) // 【纸感风去阴影】
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(-5, 5),
                    ),
                ],
                border: Border.all(
                  color: currentTheme.textColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // --- Header ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        if (_currentLevel == MenuLevel.root)
                          Icon(Icons.widgets_outlined, color: theme.colorScheme.primary)
                        else
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, size: 18, color: currentTheme.textColor),
                            onPressed: _navigateBack,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            _title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: currentTheme.textColor,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: Icon(Icons.close, color: currentTheme.textColor.withValues(alpha: 0.7)),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  // --- Body ---
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation);
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                      child: _buildBody(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentLevel) {
      case MenuLevel.root:
        return RootView(
          key: const ValueKey('root'),
          onNavigate: (levelKey, title) {
            MenuLevel level;
            if (levelKey == 'outline') {
              level = MenuLevel.outline;
            } else if (levelKey == 'settings') {
              level = MenuLevel.settings;
            } else {
              level = MenuLevel.character;
            }
            _navigateTo(level, title);
          },
        );
      case MenuLevel.settings:
        return const SettingsView(key: ValueKey('settings'));
      case MenuLevel.outline:
        return const OutlineView(key: ValueKey('outline'));
      case MenuLevel.character:
        return const CharacterView(key: ValueKey('character'));
    }
  }
}

