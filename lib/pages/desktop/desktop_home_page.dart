import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

import 'package:monet_writer/pages/desktop/bookshelf_view.dart';
import 'package:monet_writer/pages/desktop/desktop_statistics_view.dart';
import 'package:monet_writer/pages/desktop/desktop_settings_view.dart';
import 'package:monet_writer/pages/desktop/desktop_sidebar_avatar.dart';
import 'package:monet_writer/pages/desktop/desktop_trash_view.dart';
import 'package:monet_writer/pages/desktop/desktop_inspirations_view.dart';
import 'package:monet_writer/pages/desktop/components/desktop_sync_dialog.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const BookshelfView(),
    const DesktopInspirationsView(),
    const DesktopStatisticsView(),
    const DesktopTrashView(),
    const DesktopSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPaper = themeProvider.isPaperOrParchment;
    final currentTheme = userProvider.currentTheme;
    final themeData = Theme.of(context);
    final primaryColor = themeData.colorScheme.primary;

    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final bgColor = (isPaper || isNeumorphic)
        ? themeData.scaffoldBackgroundColor
        : currentTheme.backgroundColor;

    final isDark = bgColor.computeLuminance() < 0.5;

    final sidebarColor = isPaper
        ? Color.lerp(bgColor, themeProvider.seedColor, isDark ? 0.12 : 0.06)
        : Color.lerp(currentTheme.backgroundColor, themeProvider.seedColor, 0.06);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeSlideEntrance(
        child: Row(
          children: [
            Container(
              width: 240,
              margin: isNeumorphic ? const EdgeInsets.only(left: 16, top: 16, bottom: 16) : null,
              decoration: BoxDecoration(
                color: isNeumorphic ? Theme.of(context).colorScheme.surfaceContainerHighest : sidebarColor,
                borderRadius: isNeumorphic ? BorderRadius.circular(20) : null,
                boxShadow: isNeumorphic ? ThemeProvider.neumorphicConvexShadow(context) : null,
                border: isNeumorphic
                    ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1)
                    : (isPaper ? Border(right: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.06), width: 1)) : null),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Center(child: DesktopSidebarAvatar()),
                  const SizedBox(height: 32),
                  _SidebarItem(icon: CupertinoIcons.book, label: '我的作品', isSelected: _selectedIndex == 0, isPaper: isPaper, currentTheme: currentTheme, primaryColor: primaryColor, isNeumorphic: isNeumorphic, onTap: () => setState(() => _selectedIndex = 0)),
                  _SidebarItem(icon: CupertinoIcons.lightbulb, label: '灵感碎片', isSelected: _selectedIndex == 1, isPaper: isPaper, currentTheme: currentTheme, primaryColor: primaryColor, isNeumorphic: isNeumorphic, onTap: () => setState(() => _selectedIndex = 1)),
                  _SidebarItem(icon: CupertinoIcons.chart_bar_alt_fill, label: '码字统计', isSelected: _selectedIndex == 2, isPaper: isPaper, currentTheme: currentTheme, primaryColor: primaryColor, isNeumorphic: isNeumorphic, onTap: () => setState(() => _selectedIndex = 2)),
                  _SidebarItem(icon: CupertinoIcons.trash, label: '回收站', isSelected: _selectedIndex == 3, isPaper: isPaper, currentTheme: currentTheme, primaryColor: primaryColor, isNeumorphic: isNeumorphic, onTap: () => setState(() => _selectedIndex = 3)),

                  const Spacer(),

                  _SidebarItem(
                    icon: CupertinoIcons.qrcode_viewfinder,
                    label: '局域网同步',
                    isSelected: false,
                    isPaper: isPaper,
                    currentTheme: currentTheme,
                    primaryColor: primaryColor,
                    isNeumorphic: isNeumorphic,
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => DesktopSyncDialog(isPaper: isPaper),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _SidebarItem(icon: CupertinoIcons.settings, label: '全局设置', isSelected: _selectedIndex == 4, isPaper: isPaper, currentTheme: currentTheme, primaryColor: primaryColor, isNeumorphic: isNeumorphic, onTap: () => setState(() => _selectedIndex = 4)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _views),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isPaper;
  final bool isNeumorphic;
  final WritingTheme currentTheme;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isPaper,
    required this.isNeumorphic,
    required this.currentTheme,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentTheme.backgroundColor.computeLuminance() < 0.5;
    final inactiveColor = widget.currentTheme.textColor.withValues(alpha: 0.5);

    Color safeActiveColor = widget.primaryColor;
    if (widget.isPaper && !isDark && safeActiveColor.computeLuminance() > 0.4) {
      safeActiveColor = Color.lerp(safeActiveColor, Colors.black, 0.3)!;
    }

    final activeColor = widget.isNeumorphic ? Theme.of(context).colorScheme.primary : safeActiveColor;
    final iconColor = widget.isSelected ? activeColor : inactiveColor;
    final textColor = widget.isSelected ? activeColor : inactiveColor;

    Color backgroundColor = Colors.transparent;
    List<BoxShadow>? capsuleShadow;
    Border? capsuleBorder;

    if (widget.isSelected) {
      if (widget.isNeumorphic) {
        // 新拟态选中：用比侧栏更深的表面 + 亮边框，形成"按入面板"凹陷感（双信号）
        backgroundColor = Theme.of(context).colorScheme.surfaceContainer;
        capsuleShadow = ThemeProvider.neumorphicConcaveShadow(context, isDark: isDark);
        capsuleBorder = Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1);
      } else if (widget.isPaper) {
        backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
        if (!isDark) {
          capsuleShadow = [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))];
        }
      } else {
        backgroundColor = safeActiveColor.withValues(alpha: 0.12);
      }
    } else if (_isHovered) {
      backgroundColor = widget.currentTheme.textColor.withValues(alpha: 0.04);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: MonetDurations.micro,
            curve: MonetCurves.press,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: capsuleShadow,
              border: capsuleBorder,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(widget.icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600, color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

