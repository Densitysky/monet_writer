import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
// 【新增】引入我们刚刚升级的全局色彩管家（请确保路径与你实际存放位置一致）
import 'package:monet_writer/utils/color_generator.dart';

class DesktopColorPickerPanel extends StatelessWidget {
  final bool isFlat;
  const DesktopColorPickerPanel({super.key, required this.isFlat});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentSeed = themeProvider.seedColor;

    final List<Color> colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.orange, Colors.deepOrange,
      const Color(0xFFE2B2B1), const Color(0xFFB3928B), const Color(0xFF91807A), const Color(0xFFC4CBD8),
      const Color(0xFFA5B2C1), const Color(0xFF9EA4AF), const Color(0xFFB5C4B1), const Color(0xFF8B968D),
      const Color(0xFFD4C4B7), const Color(0xFFE8D3C3), const Color(0xFFD9D0C1), const Color(0xFFB4A992),
      const Color(0xFF2C3E50), const Color(0xFF1A5276), const Color(0xFF117A65), const Color(0xFF196F3D),
      const Color(0xFF7D6608), const Color(0xFF935116), const Color(0xFF7B241C), const Color(0xFF512E5F),
      const Color(0xFF4A235A), const Color(0xFF154360), const Color(0xFF424949), const Color(0xFF1B2631),
    ];

    return Wrap(
      spacing: 16, runSpacing: 16,
      alignment: WrapAlignment.start,
      children: List.generate(colors.length, (i) {
        final c = colors[i];
        final isSelected = c.toARGB32() == currentSeed.toARGB32();

        // 提取该背景色下最符合 WCAG 标准的极性色（纯黑或纯白）
        final wcagColor = ColorGenerator.getWcagTextColor(c);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => themeProvider.setSeedColor(c),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    // 【优化】：选中外边框也同步变色，确保在极浅色背景下外圈依然清晰
                    border: isSelected ? Border.all(color: wcagColor, width: 2) : null,
                    boxShadow: isFlat ? null : [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                ),
                // 【核心升级】：打勾图标智能适配 WCAG 标准
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: wcagColor,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}