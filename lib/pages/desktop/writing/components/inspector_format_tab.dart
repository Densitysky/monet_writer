import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/utils/text_format_util.dart';
import 'package:monet_writer/pages/writing/components/word_goal_widget.dart';

class InspectorFormatTab extends StatelessWidget {
  final WritingTheme currentTheme;
  final bool isPaper;
  final Color primaryColor;

  const InspectorFormatTab({
    super.key,
    required this.currentTheme,
    required this.isPaper,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final provider = context.watch<WritingProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // ================= 1. 视觉主题 =================
        _buildSectionTitle('视觉与主题'),
        const SizedBox(height: 12),
        _buildContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(UserProvider.themes.length, (index) {
                  final item = UserProvider.themes[index];
                  final isSelected = userProvider.themeIndex == index;
                  return GestureDetector(
                    onTap: () => userProvider.updateTheme(index),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? primaryColor : currentTheme.textColor.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
                        boxShadow: isSelected && !isPaper ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 6)] : [],
                      ),
                      child: isSelected ? Icon(Icons.check, color: item.textColor, size: 16) : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('背景毛玻璃效果', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: currentTheme.textColor.withValues(alpha: 0.1),
                      value: userProvider.isBackgroundBlurred,
                      onChanged: (val) => userProvider.toggleBackgroundBlur(val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ================= 2. 字体与排版 =================
        _buildSectionTitle('字体排版'),
        const SizedBox(height: 12),
        _buildContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_fontLabel(userProvider.fontFamily), style: TextStyle(fontSize: 13, color: currentTheme.textColor), overflow: TextOverflow.ellipsis),
                  ),
                  if (userProvider.fontFamily == "CustomFont")
                    TextButton(
                      onPressed: userProvider.resetFont,
                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('重置', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6))),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: userProvider.loadLocalFont,
                    style: FilledButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    child: const Text('导入', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FontChip(label: '系统', family: 'System', userProvider: userProvider, primaryColor: primaryColor, currentTheme: currentTheme),
                  const SizedBox(width: 8),
                  _FontChip(label: '衬线体', family: 'NotoSerifSC', userProvider: userProvider, primaryColor: primaryColor, currentTheme: currentTheme),
                  const SizedBox(width: 8),
                  _FontChip(label: '自定义', family: 'CustomFont', userProvider: userProvider, primaryColor: primaryColor, currentTheme: currentTheme, onTap: () => userProvider.loadLocalFont()),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(width: 40, child: Text('字号', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6)))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                      child: Slider(
                        value: userProvider.fontSize, min: 12, max: 30, divisions: 18,
                        onChanged: (v) => userProvider.updateWritingConfig(fontSize: v),
                      ),
                    ),
                  ),
                  SizedBox(width: 24, child: Text(userProvider.fontSize.toInt().toString(), style: TextStyle(fontSize: 12, color: currentTheme.textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),

              Row(
                children: [
                  SizedBox(width: 40, child: Text('行高', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6)))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                      child: Slider(
                        value: userProvider.lineHeight, min: 1.0, max: 3.0, divisions: 20,
                        onChanged: (v) => userProvider.updateWritingConfig(lineHeight: v),
                      ),
                    ),
                  ),
                  SizedBox(width: 24, child: Text(userProvider.lineHeight.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: currentTheme.textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),

              // 【核心新增】：段落间距无级滑块
              Row(
                children: [
                  SizedBox(width: 40, child: Text('段距', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6)))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                      child: Slider(
                        value: userProvider.paragraphSpacing, min: 0.0, max: 40.0, divisions: 20,
                        onChanged: (v) => userProvider.updateWritingConfig(paragraphSpacing: v),
                      ),
                    ),
                  ),
                  SizedBox(width: 24, child: Text(userProvider.paragraphSpacing.toInt().toString(), style: TextStyle(fontSize: 12, color: currentTheme.textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ================= 3. 沉浸排版风格（桌面端专属） =================
        _buildSectionTitle('沉浸排版风格'),
        const SizedBox(height: 12),
        _buildContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择 F11 全屏沉浸时的视觉风格', style: TextStyle(fontSize: 11, color: currentTheme.textColor.withValues(alpha: 0.4))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ImmersiveStyleChip(
                    label: '纸页画布',
                    isSelected: userProvider.desktopImmersiveStyle == 0,
                    onTap: () => userProvider.setDesktopImmersiveStyle(0),
                    primaryColor: primaryColor,
                    currentTheme: currentTheme,
                  ),
                  _ImmersiveStyleChip(
                    label: '聚焦光束',
                    isSelected: userProvider.desktopImmersiveStyle == 1,
                    onTap: () => userProvider.setDesktopImmersiveStyle(1),
                    primaryColor: primaryColor,
                    currentTheme: currentTheme,
                  ),
                  _ImmersiveStyleChip(
                    label: '氛围光晕',
                    isSelected: userProvider.desktopImmersiveStyle == 2,
                    onTap: () => userProvider.setDesktopImmersiveStyle(2),
                    primaryColor: primaryColor,
                    currentTheme: currentTheme,
                  ),
                  _ImmersiveStyleChip(
                    label: '打字机',
                    isSelected: userProvider.desktopImmersiveStyle == 3,
                    onTap: () => userProvider.setDesktopImmersiveStyle(3),
                    primaryColor: primaryColor,
                    currentTheme: currentTheme,
                  ),
                  _ImmersiveStyleChip(
                    label: '工作室',
                    isSelected: userProvider.desktopImmersiveStyle == 4,
                    onTap: () => userProvider.setDesktopImmersiveStyle(4),
                    primaryColor: primaryColor,
                    currentTheme: currentTheme,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ================= 3. 辅助工具 =================
        _buildSectionTitle('写作辅助'),
        const SizedBox(height: 12),
        _buildContainer(
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  final tempController = TextEditingController(text: provider.contentController.text);
                  tempController.selection = provider.contentController.selection;
                  TextFormatUtil.autoFormat(
                    tempController,
                        () {
                      provider.contentController.text = tempController.text;
                      provider.contentController.selection = tempController.selection;
                      provider.onContentChanged();
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 排版完成：已自动缩进并清理多余空行'), behavior: SnackBarBehavior.floating));
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.format_align_left, color: primaryColor, size: 18),
                      const SizedBox(width: 12),
                      Text('一键自动排版', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                      const Spacer(),
                      const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              Divider(height: 24, color: currentTheme.textColor.withValues(alpha: 0.05)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.flag, color: primaryColor, size: 18),
                    const SizedBox(width: 12),
                    Text('本章字数目标', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                    const Spacer(),
                    WordGoalWidget(currentWordCount: provider.currentChapter?.wordCount ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5));
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0),
        border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  static String _fontLabel(String family) {
    switch (family) {
      case 'System':
        return '当前：系统默认';
      case 'NotoSerifSC':
        return '当前：衬线体';
      case 'CustomFont':
        return '当前：自定义字体';
      default:
        return '当前：$family';
    }
  }
}

class _ImmersiveStyleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final WritingTheme currentTheme;

  const _ImmersiveStyleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: primaryColor.withValues(alpha: 0.15),
      backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : currentTheme.textColor.withValues(alpha: 0.6),
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : currentTheme.textColor.withValues(alpha: 0.1),
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _FontChip extends StatelessWidget {
  final String label;
  final String family;
  final UserProvider userProvider;
  final Color primaryColor;
  final WritingTheme currentTheme;
  final VoidCallback? onTap;

  const _FontChip({
    required this.label,
    required this.family,
    required this.userProvider,
    required this.primaryColor,
    required this.currentTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = userProvider.fontFamily == family;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        if (onTap != null && family == 'CustomFont') {
          onTap!();
        } else {
          userProvider.setFontFamily(family);
        }
      },
      selectedColor: primaryColor.withValues(alpha: 0.15),
      backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : currentTheme.textColor.withValues(alpha: 0.6),
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : currentTheme.textColor.withValues(alpha: 0.1),
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}
