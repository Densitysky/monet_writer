import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<UserProvider>();
    final currentTheme = settings.currentTheme;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: currentTheme.textColor);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: currentTheme.textColor);
    final subtitleStyle = TextStyle(color: currentTheme.textColor.withValues(alpha: 0.6), fontSize: 13);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // 1. 主题选择
        Text('阅读主题', style: titleStyle),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(UserProvider.themes.length, (index) {
              final item = UserProvider.themes[index];
              final isSelected = settings.themeIndex == index;
              return GestureDetector(
                onTap: () => settings.updateTheme(index),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : currentTheme.textColor.withValues(alpha: 0.1),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8),
                    ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: item.textColor, size: 20)
                      : null,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),
        Divider(color: currentTheme.textColor.withValues(alpha: 0.1)),

        // 2. 个性化设置
        Text('个性化', style: titleStyle),

        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('背景毛玻璃效果', style: bodyStyle),
          subtitle: Text('让文字在背景上更清晰', style: subtitleStyle),
          trailing: CupertinoSwitch(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: currentTheme.textColor.withValues(alpha: 0.1),
            value: settings.isBackgroundBlurred,
            onChanged: (val) => settings.toggleBackgroundBlur(val),
          ),
          onTap: () => settings.toggleBackgroundBlur(!settings.isBackgroundBlurred),
        ),

        Divider(color: currentTheme.textColor.withValues(alpha: 0.1)),

        // 3. 字体设置
        Text('字体设置', style: titleStyle),
        const SizedBox(height: 12),
        Text(_fontLabel(settings.fontFamily), style: bodyStyle?.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _FontChip(
              label: '系统默认',
              isSelected: settings.fontFamily == 'System',
              onTap: () => settings.setFontFamily('System'),
            ),
            _FontChip(
              label: '衬线体',
              isSelected: settings.fontFamily == 'NotoSerifSC',
              onTap: () => settings.setFontFamily('NotoSerifSC'),
            ),
            _FontChip(
              label: '自定义',
              isSelected: settings.fontFamily == 'CustomFont',
              onTap: settings.loadLocalFont,
            ),
          ],
        ),
        if (settings.fontFamily == 'CustomFont')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: settings.resetFont,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('恢复系统默认'),
            ),
          ),

        const SizedBox(height: 16),
        Text('字号: ${settings.fontSize.toInt()}', style: bodyStyle),
        Slider(
          value: settings.fontSize,
          min: 12,
          max: 30,
          divisions: 18,
          label: settings.fontSize.toInt().toString(),
          onChanged: (v) => settings.updateWritingConfig(fontSize: v),
        ),

        Text('行高: ${settings.lineHeight.toStringAsFixed(1)}', style: bodyStyle),
        Slider(
          value: settings.lineHeight,
          min: 1.0,
          max: 3.0,
          divisions: 20,
          label: settings.lineHeight.toStringAsFixed(1),
          onChanged: (v) => settings.updateWritingConfig(lineHeight: v),
        ),

        // 【核心新增】：段落间距全局设置
        Text('段距: ${settings.paragraphSpacing.toInt()}px', style: bodyStyle),
        Slider(
          value: settings.paragraphSpacing,
          min: 0.0,
          max: 40.0,
          divisions: 20,
          label: settings.paragraphSpacing.toInt().toString(),
          onChanged: (v) => settings.updateWritingConfig(paragraphSpacing: v),
        ),
      ],
    );
  }

  static String _fontLabel(String family) {
    switch (family) {
      case 'System':
        return '当前：系统默认 (无衬线)';
      case 'NotoSerifSC':
        return '当前：衬线体 (更适合长篇阅读)';
      case 'CustomFont':
        return '当前：自定义字体';
      default:
        return '当前：$family';
    }
  }
}

class _FontChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}