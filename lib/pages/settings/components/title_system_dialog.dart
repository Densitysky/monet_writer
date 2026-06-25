import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

class TitleSystemDialog extends StatefulWidget {
  final bool isFlat;
  const TitleSystemDialog({super.key, required this.isFlat});

  @override
  State<TitleSystemDialog> createState() => _TitleSystemDialogState();
}

class _TitleSystemDialogState extends State<TitleSystemDialog> {
  late int _selectedIndex;
  late List<String> _customTitles;
  final List<TextEditingController> _controllers = [];
  final _scrollController = ScrollController();
  final int _hoveredCard = -1;

  static const limits = [
    '0-1万字', '1-5万字', '5-15万字', '15-50万字',
    '50-100万字', '100-200万字', '200-500万字', '500-1000万字', '1000万字+',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _selectedIndex = user.titleSystemIndex;
    _customTitles = List.from(user.customTitles);
    for (var t in _customTitles) {
      _controllers.add(TextEditingController(text: t));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final textColor = user.currentTheme.textColor;
    final mutedColor = textColor.withValues(alpha: 0.5);
    final surfaceColor = textColor.withValues(alpha: 0.04);
    final primaryColor = theme.colorScheme.primary;
    final isCustom = _selectedIndex == UserProvider.customTitleIndex;

    final currentLevelIdx = user.currentLevelIndex;
    final currentTitle = user.currentLevelTitle;
    final wordCount = user.totalWords;
    final nextThreshold = currentLevelIdx < 8
        ? _thresholdForLevel(currentLevelIdx + 1)
        : wordCount;
    final prevThreshold = currentLevelIdx > 0
        ? _thresholdForLevel(currentLevelIdx)
        : 0;
    final progress = nextThreshold > prevThreshold
        ? ((wordCount - prevThreshold) / (nextThreshold - prevThreshold)).clamp(0.0, 1.0)
        : 1.0;

    return Dialog(
      backgroundColor: user.currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 8.0 : 16.0)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleBar(textColor, primaryColor),
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(currentLevelIdx, currentTitle, wordCount, nextThreshold, prevThreshold, progress, primaryColor, mutedColor, textColor),
                    const SizedBox(height: 20),
                    _buildSectionLabel('选择体系', mutedColor),
                    const SizedBox(height: 10),
                    _buildSystemCards(primaryColor, mutedColor, surfaceColor, textColor),
                    const SizedBox(height: 20),
                    if (isCustom)
                      _buildCustomEditor(textColor, mutedColor, surfaceColor)
                    else
                      _buildLevelPreview(primaryColor, currentLevelIdx, mutedColor, surfaceColor, textColor),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomBar(user, primaryColor, mutedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text('成就与境界体系', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int idx, String title, int words, int nextTh, int prevTh, double p, Color primary, Color muted, Color text) {
    final remaining = nextTh > words ? nextTh - words : 0;
    final nextTitle = idx < 8
        ? (_selectedIndex == UserProvider.customTitleIndex
            ? _customTitles[idx + 1]
            : UserProvider.presetTitles[_selectedIndex][idx + 1])
        : '已达巅峰';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前境界', style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary)),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? '已写 ${_fmtWords(words)} · 距「$nextTitle」还差 ${_fmtWords(remaining)}'
                      : '已写 ${_fmtWords(words)} · 已达巅峰',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: p,
                    minHeight: 4,
                    backgroundColor: primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color muted) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted, letterSpacing: 0.5));
  }

  Widget _buildSystemCards(Color primary, Color muted, Color surface, Color text) {
    const systems = UserProvider.systemInfo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 420 ? 3 : 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(systems.length, (i) {
            final isSelected = _selectedIndex == i;
            final info = systems[i];
            return SizedBox(
              width: (w - (cols - 1) * 10) / cols,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? primary.withValues(alpha: 0.06) : surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primary : text.withValues(alpha: 0.12),
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _iconForSystem(i),
                        size: 18,
                        color: isSelected ? primary : muted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info['name']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? primary : text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info['subtitle']!,
                        style: TextStyle(fontSize: 10, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLevelPreview(Color primary, int currentIdx, Color muted, Color surface, Color text) {
    final titles = UserProvider.presetTitles[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('等级一览', muted),
        const SizedBox(height: 8),
        ...List.generate(9, (i) {
          final isCurrent = i == currentIdx;
          final isUnlocked = i <= currentIdx;
          final title = titles[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: isCurrent ? 10 : 7),
            decoration: BoxDecoration(
              color: isCurrent ? primary : (isUnlocked ? surface : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? primary : Colors.transparent,
                    border: isUnlocked ? null : Border.all(color: text.withValues(alpha: 0.15), width: 1.5),
                  ),
                ),
                SizedBox(width: isCurrent ? 6 : 8),
                Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrent ? Colors.white : (isUnlocked ? muted : text.withValues(alpha: 0.25)),
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCurrent ? Colors.white : (isUnlocked ? text : text.withValues(alpha: 0.3)),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  limits[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrent ? Colors.white.withValues(alpha: 0.7) : (isUnlocked ? muted : text.withValues(alpha: 0.2)),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomEditor(Color text, Color muted, Color surface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('自定义头衔（输入你想要的 9 级头衔）', muted),
        const SizedBox(height: 8),
        ...List.generate(9, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lv.${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
                      Text(limits[i], style: TextStyle(fontSize: 10, color: text.withValues(alpha: 0.25))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _controllers[i],
                      style: TextStyle(fontSize: 13, color: text),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(UserProvider user, Color primary, Color muted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: muted.withValues(alpha: 0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var c in _controllers) {
                  c.text = '';
                }
              });
            },
            child: Text('重置默认', style: TextStyle(color: muted, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: muted, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              user.setTitleSystemIndex(_selectedIndex);
              if (_selectedIndex == UserProvider.customTitleIndex) {
                user.updateCustomTitles(_controllers.map((e) => e.text.isNotEmpty ? e.text : 'Lv.${_controllers.indexOf(e) + 1} 自定义').toList());
              }
              Navigator.pop(context);
            },
            child: const Text('保存应用'),
          ),
        ],
      ),
    );
  }

  int _thresholdForLevel(int level) {
    const thresholds = [0, 10000, 50000, 150000, 500000, 1000000, 2000000, 5000000, 10000000];
    if (level >= thresholds.length) return thresholds.last * 2;
    return thresholds[level];
  }

  String _fmtWords(int w) {
    if (w >= 10000) return '${(w / 10000).toStringAsFixed(1)}万字';
    return '$w字';
  }

  IconData _iconForSystem(int idx) {
    const icons = [
      Icons.auto_awesome,  // 东方修仙
      Icons.edit_note,     // 网文作家
      Icons.auto_awesome,  // 西幻魔法 (reuse)
      Icons.bolt,          // JOJO
      Icons.sports_kabaddi, // 武侠
      Icons.rocket_launch, // 科幻
      Icons.edit,          // 自定义
    ];
    return icons[idx.clamp(0, icons.length - 1)];
  }
}
