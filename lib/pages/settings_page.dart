import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/pages/settings/ai_config_page.dart';
import 'package:monet_writer/pages/settings/data_manage_page.dart';
import 'package:monet_writer/pages/settings/ai_prompts_page.dart';
// 【新增】：引入境界体系弹窗
import 'package:monet_writer/pages/settings/components/title_system_dialog.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // --- 分组 1: 个性化 ---
          const _SectionHeader(title: '个性化'),

          // 【新增】：成就与境界体系入口
          ListTile(
            title: const Text('成就与境界体系'),
            subtitle: const Text('设置修仙、JOJO、武侠等多风格头衔'),
            trailing: const Icon(Icons.auto_awesome),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => TitleSystemDialog(isFlat: isFlat),
              );
            },
          ),

          ListTile(
            title: const Text('主页背景模糊'),
            subtitle: const Text('开启后，个人中心背景图将应用高斯模糊'),
            trailing: CupertinoSwitch(
              activeTrackColor: theme.colorScheme.primary,
              value: userProvider.isBackgroundBlurred,
              onChanged: (value) => userProvider.toggleBackgroundBlur(value),
            ),
            onTap: () => userProvider.toggleBackgroundBlur(!userProvider.isBackgroundBlurred),
          ),

          ListTile(
            title: const Text('视觉风格'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<AppThemeStyle>(
                  style: SegmentedButton.styleFrom(selectedBackgroundColor: theme.colorScheme.primaryContainer),
                  segments: const [
                    ButtonSegment(value: AppThemeStyle.modern, label: Text('现代'), icon: Icon(Icons.water_drop, size: 14)),
                    ButtonSegment(value: AppThemeStyle.flat, label: Text('极简'), icon: Icon(Icons.grid_view_rounded, size: 14)),
                    ButtonSegment(value: AppThemeStyle.golden, label: Text('黄金'), icon: Icon(Icons.auto_awesome, size: 14)),
                  ],
                  selected: {themeProvider.themeStyle},
                  onSelectionChanged: (s) => themeProvider.setThemeStyle(s.first),
                ),
                if (themeProvider.themeStyle == AppThemeStyle.golden) ...[
                  const SizedBox(height: 12),
                  Text('配色方案', style: TextStyle(fontSize: 13, color: theme.colorScheme.outline)),
                  const SizedBox(height: 6),
                  SegmentedButton<ColorPalette>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: theme.colorScheme.primaryContainer,
                      selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                    segments: const [
                      ButtonSegment(value: ColorPalette.goldenAngle, label: Text('金律'), icon: Icon(Icons.auto_awesome, size: 13)),
                      ButtonSegment(value: ColorPalette.chinese, label: Text('中国色'), icon: Icon(Icons.brush, size: 13)),
                      ButtonSegment(value: ColorPalette.japanese, label: Text('和色'), icon: Icon(Icons.landslide, size: 13)),
                    ],
                    selected: {themeProvider.colorPalette},
                    onSelectionChanged: (s) => themeProvider.setColorPalette(s.first),
                  ),
                ],
              ],
            ),
          ),

          ListTile(
            title: const Text('主题颜色'),
            subtitle: Text('当前色值: #${themeProvider.seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'),
            trailing: CircleAvatar(
              backgroundColor: themeProvider.seedColor,
              radius: 12,
            ),
            onTap: () => _showColorPicker(context, themeProvider),
          ),
          ListTile(
            title: const Text('外观模式'),
            subtitle: Text(themeProvider.themeMode == ThemeMode.system ? '跟随系统' : (themeProvider.themeMode == ThemeMode.light ? '浅色模式' : '深色模式')),
            trailing: const Icon(Icons.brightness_medium),
            onTap: () => _showThemeModeDialog(context, themeProvider),
          ),

          const Divider(),

          // --- 分组 2: AI 与写作 ---
          const _SectionHeader(title: 'AI 与写作'),
          ListTile(
            title: const Text('AI 引擎配置'),
            subtitle: const Text('设置 API Key 与模型参数'),
            leading: const Icon(Icons.smart_toy_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MonetPageRoute(builder: (_) => const AiConfigPage()));
            },
          ),
          ListTile(
            title: const Text('AI 提示词管理'),
            subtitle: const Text('自定义扩写、润色等指令模板'),
            leading: const Icon(Icons.chat_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MonetPageRoute(builder: (_) => const AiPromptsPage()));
            },
          ),

          const Divider(),

          // --- 分组 3: 数据与备份 ---
          const _SectionHeader(title: '数据与安全'),
          ListTile(
            title: const Text('数据备份与恢复'),
            subtitle: const Text('导出本地数据或从备份还原'),
            leading: const Icon(Icons.backup_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MonetPageRoute(builder: (_) => const DataManagePage()));
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 多风格色盘选择
  void _showColorPicker(BuildContext context, ThemeProvider provider) {
    final isFlat = context.read<ThemeProvider>().themeStyle == AppThemeStyle.flat;
    final currentSeed = provider.seedColor;
    final goldenC = ThemeProvider.goldenAngleColors;
    final chineseC = ThemeProvider.chineseColors;
    final japaneseC = ThemeProvider.japaneseColors;

    void onPick(Color c, {ColorPalette? toPalette}) {
      provider.setSeedColor(c);
      if (toPalette != null && provider.colorPalette != toPalette) {
        provider.setColorPalette(toPalette);
      }
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择主题色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildColorRow('金律原色', goldenC.sublist(0, 6), currentSeed, ctx, () => {}, paletteHint: ColorPalette.goldenAngle),
                  const SizedBox(height: 12),
                  _buildColorRow('莫奈自然色', goldenC.sublist(6, 12), currentSeed, ctx, () => {}, paletteHint: ColorPalette.goldenAngle),
                  const SizedBox(height: 12),
                  _buildColorRow('深沉色', goldenC.sublist(12, 18), currentSeed, ctx, () => {}, paletteHint: ColorPalette.goldenAngle),
                  const SizedBox(height: 12),
                  _buildColorRow('无色系', goldenC.sublist(18, 24), currentSeed, ctx, () => {}, paletteHint: ColorPalette.goldenAngle),
                  const Divider(height: 32),
                  _buildColorRow('中国色·青', chineseC.sublist(0, 6), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.chinese), paletteHint: ColorPalette.chinese),
                  const SizedBox(height: 12),
                  _buildColorRow('中国色·暖', chineseC.sublist(6, 12), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.chinese), paletteHint: ColorPalette.chinese),
                  const SizedBox(height: 12),
                  _buildColorRow('中国色·淡', chineseC.sublist(12, 18), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.chinese), paletteHint: ColorPalette.chinese),
                  const SizedBox(height: 12),
                  _buildColorRow('中国色·艳', chineseC.sublist(18, 24), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.chinese), paletteHint: ColorPalette.chinese),
                  const Divider(height: 32),
                  _buildColorRow('和色·青', japaneseC.sublist(0, 6), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.japanese), paletteHint: ColorPalette.japanese),
                  const SizedBox(height: 12),
                  _buildColorRow('和色·暖', japaneseC.sublist(6, 12), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.japanese), paletteHint: ColorPalette.japanese),
                  const SizedBox(height: 12),
                  _buildColorRow('和色·淡', japaneseC.sublist(12, 18), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.japanese), paletteHint: ColorPalette.japanese),
                  const SizedBox(height: 12),
                  _buildColorRow('和色·深', japaneseC.sublist(18, 24), currentSeed, ctx, () => provider.setColorPalette(ColorPalette.japanese), paletteHint: ColorPalette.japanese),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, List<Color> rowColors, Color currentSeed, BuildContext ctx, VoidCallback onPaletteSwitch, {ColorPalette? paletteHint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.outline)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: rowColors.map((c) {
            final isSelected = c.toARGB32() == currentSeed.toARGB32();
            return GestureDetector(
              onTap: () {
                Provider.of<ThemeProvider>(ctx, listen: false).setSeedColor(c);
                if (paletteHint != null && Provider.of<ThemeProvider>(ctx, listen: false).colorPalette != paletteHint) {
                  Provider.of<ThemeProvider>(ctx, listen: false).setColorPalette(paletteHint);
                }
                Navigator.pop(ctx);
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 2.5) : null,
                ),
                child: isSelected ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 20) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeProvider provider) {
    final isFlat = context.read<ThemeProvider>().themeStyle == AppThemeStyle.flat;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择外观模式'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text('跟随系统'),
                leading: const Icon(Icons.brightness_auto),
                onTap: () { provider.setThemeMode(ThemeMode.system); Navigator.pop(context); }
            ),
            ListTile(
                title: const Text('浅色模式'),
                leading: const Icon(Icons.light_mode),
                onTap: () { provider.setThemeMode(ThemeMode.light); Navigator.pop(context); }
            ),
            ListTile(
                title: const Text('深色模式'),
                leading: const Icon(Icons.dark_mode),
                onTap: () { provider.setThemeMode(ThemeMode.dark); Navigator.pop(context); }
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}