import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

// 引入彻底解耦的模块化组件
import 'package:monet_writer/pages/desktop/settings/desktop_color_picker_panel.dart';
import 'package:monet_writer/pages/desktop/settings/desktop_ai_config_panel.dart';
import 'package:monet_writer/pages/desktop/settings/desktop_ai_prompts_panel.dart';
import 'package:monet_writer/pages/desktop/settings/desktop_data_manage_panel.dart';
// 【新增】：引入境界体系弹窗
import 'package:monet_writer/pages/settings/components/title_system_dialog.dart';

/// 桌面端：全局设置主控制台 (模块化架构)
class DesktopSettingsView extends StatelessWidget {
  const DesktopSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: currentTheme.backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            children: [
              Text('全局设置', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: currentTheme.textColor, letterSpacing: 1.2)),
              const SizedBox(height: 40),

              // ==================== 1. 外观与个性化 ====================
              _buildSectionTitle('外观与个性化', CupertinoIcons.paintbrush, currentTheme, primaryColor),
              _buildSettingCard(
                isFlat: isFlat, currentTheme: currentTheme,
                child: Column(
                  children: [
                    // 【新增】：成就与境界体系设置入口
                    _buildSettingRow(
                      title: '成就与境界体系',
                      subtitle: '设置侧边栏和主页的修仙、西幻或自定义头衔',
                      currentTheme: currentTheme,
                      trailing: FilledButton.tonalIcon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => TitleSystemDialog(isFlat: isFlat),
                          );
                        },
                        icon: const Icon(Icons.military_tech, size: 18),
                        label: const Text('修改体系'),
                      ),
                    ),
                    Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

                    _buildSettingRow(
                      title: '主页背景模糊', subtitle: '开启后，个人中心背景图将应用高斯模糊', currentTheme: currentTheme,
                      trailing: CupertinoSwitch(
                        activeTrackColor: primaryColor,
                        value: userProvider.isBackgroundBlurred,
                        onChanged: (val) => userProvider.toggleBackgroundBlur(val),
                      ),
                    ),
                    Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),
                    _buildSettingRow(
                      title: '深浅色模式', subtitle: '跟随系统或强制指定界面的明暗', currentTheme: currentTheme,
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('系统', style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: ThemeMode.light, label: Text('浅色', style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: ThemeMode.dark, label: Text('深色', style: TextStyle(fontSize: 12))),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (set) => themeProvider.setThemeMode(set.first),
                        style: ButtonStyle(shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)))),
                      ),
                    ),
                    Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),
                    _buildSettingRow(
                      title: 'UI 视觉风格', subtitle: '极简扁平风 (硬朗) 或 现代拟物风 (阴影)', currentTheme: currentTheme,
                      trailing: SegmentedButton<AppThemeStyle>(
                        segments: const [
                          ButtonSegment(value: AppThemeStyle.flat, label: Text('极简扁平', style: TextStyle(fontSize: 12))),
                          ButtonSegment(value: AppThemeStyle.modern, label: Text('现代拟物', style: TextStyle(fontSize: 12))),
                        ],
                        selected: {themeProvider.themeStyle},
                        onSelectionChanged: (set) => themeProvider.setThemeStyle(set.first),
                        style: ButtonStyle(shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)))),
                      ),
                    ),
                    Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

                    // 【解耦装载】36色主题色盘
                    _ExpandableSettingRow(
                      title: '主题颜色',
                      subtitle: '当前色值: #${themeProvider.seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      currentTheme: currentTheme,
                      expandedContent: DesktopColorPickerPanel(isFlat: isFlat),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ==================== 2. AI 与写作 ====================
              _buildSectionTitle('AI 与写作', CupertinoIcons.wand_rays, currentTheme, primaryColor),
              _buildSettingCard(
                isFlat: isFlat, currentTheme: currentTheme,
                child: Column(
                  children: [
                    // 【解耦装载】AI 引擎配置
                    _ExpandableSettingRow(
                      title: 'AI 引擎配置',
                      subtitle: '展开以配置接口地址、模型名称与 API Key',
                      currentTheme: currentTheme,
                      expandedContent: DesktopAiConfigPanel(isFlat: isFlat, currentTheme: currentTheme),
                    ),
                    Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),

                    // 【解耦装载】AI 提示词管理
                    _ExpandableSettingRow(
                      title: 'AI 提示词管理',
                      subtitle: '自定义扩写、润色等指令模板',
                      currentTheme: currentTheme,
                      expandedContent: DesktopAiPromptsPanel(isFlat: isFlat, currentTheme: currentTheme, primaryColor: primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ==================== 3. 数据与安全 ====================
              _buildSectionTitle('数据与安全', CupertinoIcons.lock_shield, currentTheme, primaryColor),
              _buildSettingCard(
                isFlat: isFlat, currentTheme: currentTheme,
                child: Column(
                  children: [
                    // 【解耦装载】数据备份与恢复
                    _ExpandableSettingRow(
                      title: '数据备份与恢复',
                      subtitle: '将你的心血安全地导出或从本地恢复',
                      currentTheme: currentTheme,
                      expandedContent: DesktopDataManagePanel(isFlat: isFlat, currentTheme: currentTheme, primaryColor: primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, WritingTheme theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildSettingCard({required bool isFlat, required WritingTheme currentTheme, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isFlat ? Colors.transparent : currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
        border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSettingRow({required String title, required String subtitle, required WritingTheme currentTheme, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: currentTheme.textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.5))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// 丝滑下拉动画的手风琴组件 (内部复用逻辑)
class _ExpandableSettingRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final WritingTheme currentTheme;
  final Widget expandedContent;

  const _ExpandableSettingRow({
    required this.title,
    required this.subtitle,
    required this.currentTheme,
    required this.expandedContent,
  });

  @override
  State<_ExpandableSettingRow> createState() => _ExpandableSettingRowState();
}

class _ExpandableSettingRowState extends State<_ExpandableSettingRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: widget.currentTheme.textColor)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle, style: TextStyle(fontSize: 12, color: widget.currentTheme.textColor.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(CupertinoIcons.chevron_down, size: 16, color: widget.currentTheme.textColor.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.currentTheme.textColor.withValues(alpha: 0.02),
              border: Border(top: BorderSide(color: widget.currentTheme.textColor.withValues(alpha: 0.05))),
            ),
            padding: const EdgeInsets.all(20),
            child: widget.expandedContent,
          )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}