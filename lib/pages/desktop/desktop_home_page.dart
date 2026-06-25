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

// 【核心新增】：导入局域网同步弹窗组件
import 'package:monet_writer/pages/desktop/components/desktop_sync_dialog.dart';

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

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final themeData = Theme.of(context);
    final primaryColor = themeData.colorScheme.primary;

    final bgColor = isFlat
        ? themeData.scaffoldBackgroundColor
        : currentTheme.backgroundColor;

    final isDark = bgColor.computeLuminance() < 0.5;

    final sidebarColor = isFlat
        ? Color.lerp(bgColor, themeProvider.seedColor, isDark ? 0.12 : 0.06)
        : Color.lerp(currentTheme.backgroundColor, themeProvider.seedColor, 0.06);

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: isFlat
                  ? Border(right: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.06), width: 1))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(child: DesktopSidebarAvatar()),
                const SizedBox(height: 32),

                _SidebarItem(icon: CupertinoIcons.book, label: '我的作品', isSelected: _selectedIndex == 0, isFlat: isFlat, currentTheme: currentTheme, primaryColor: themeProvider.seedColor, onTap: () => setState(() => _selectedIndex = 0)),
                _SidebarItem(icon: CupertinoIcons.lightbulb, label: '灵感碎片', isSelected: _selectedIndex == 1, isFlat: isFlat, currentTheme: currentTheme, primaryColor: themeProvider.seedColor, onTap: () => setState(() => _selectedIndex = 1)),
                _SidebarItem(icon: CupertinoIcons.chart_bar_alt_fill, label: '码字统计', isSelected: _selectedIndex == 2, isFlat: isFlat, currentTheme: currentTheme, primaryColor: themeProvider.seedColor, onTap: () => setState(() => _selectedIndex = 2)),
                _SidebarItem(icon: CupertinoIcons.trash, label: '回收站', isSelected: _selectedIndex == 3, isFlat: isFlat, currentTheme: currentTheme, primaryColor: themeProvider.seedColor, onTap: () => setState(() => _selectedIndex = 3)),

                const Spacer(),

                // ==================== 【核心修改】：真实呼出局域网同步面板 ====================
                _SidebarItem(
                    icon: CupertinoIcons.qrcode_viewfinder,
                    label: '局域网同步',
                    isSelected: false,
                    isFlat: isFlat,
                    currentTheme: currentTheme,
                    primaryColor: themeProvider.seedColor,
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false, // 强制用户点击右上角 X 关闭，防止误触断开服务器
                        builder: (_) => DesktopSyncDialog(isFlat: isFlat),
                      );
                    }
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _SidebarItem(icon: CupertinoIcons.settings, label: '全局设置', isSelected: _selectedIndex == 4, isFlat: isFlat, currentTheme: currentTheme, primaryColor: themeProvider.seedColor, onTap: () => setState(() => _selectedIndex = 4)),
                ),
              ],
            ),
          ),

          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _views),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isFlat;
  final WritingTheme currentTheme;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.icon, required this.label, required this.isSelected, required this.isFlat, required this.currentTheme, required this.primaryColor, required this.onTap});

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
    if (widget.isFlat && !isDark && safeActiveColor.computeLuminance() > 0.4) {
      safeActiveColor = Color.lerp(safeActiveColor, Colors.black, 0.3)!;
    }

    final iconColor = widget.isSelected ? safeActiveColor : inactiveColor;
    final textColor = widget.isSelected ? safeActiveColor : inactiveColor;

    Color backgroundColor = Colors.transparent;
    List<BoxShadow>? capsuleShadow;

    if (widget.isSelected) {
      backgroundColor = widget.isFlat
          ? (isDark ? const Color(0xFF2A2A2A) : Colors.white)
          : safeActiveColor.withValues(alpha: 0.12);

      if (widget.isFlat && !isDark) {
        capsuleShadow = [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))];
      }
    } else if (_isHovered) {
      backgroundColor = widget.currentTheme.textColor.withValues(alpha: 0.04);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.isFlat ? 16.0 : 16.0, vertical: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: capsuleShadow,
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
