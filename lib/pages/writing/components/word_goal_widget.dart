import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】

class WordGoalWidget extends StatefulWidget {
  final int currentWordCount;

  const WordGoalWidget({super.key, required this.currentWordCount});

  @override
  State<WordGoalWidget> createState() => _WordGoalWidgetState();
}

class _WordGoalWidgetState extends State<WordGoalWidget> {
  int _targetGoal = 2000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _targetGoal = prefs.getInt('chapter_word_goal') ?? 2000;
        _isLoading = false;
      });
    }
  }

  Future<void> _setGoal(int newGoal) async {
    if (newGoal <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chapter_word_goal', newGoal);
    if (mounted) {
      setState(() {
        _targetGoal = newGoal;
      });
      Navigator.pop(context);
      HapticFeedback.lightImpact();
    }
  }

  void _showSettingsSheet() {
    final theme = context.read<UserProvider>().currentTheme;
    final isFlat = context.read<ThemeProvider>().themeStyle == AppThemeStyle.flat; // 【获取极简风状态】
    final TextEditingController customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 20.0)), // 【动态圆角】
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFlat) // 【极简风隐藏灰色拖拽条】
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                ),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('设定本章目标', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
                  ),
                  Positioned(
                    right: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0), // 【动态圆角】
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
                        child: Icon(CupertinoIcons.xmark, size: 20, color: theme.textColor.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: theme.textColor.withValues(alpha: 0.1)),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('快捷设定 (字)', style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 13)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [1000, 2000, 3000, 4000, 5000].map((goal) {
                        final isCurrent = goal == _targetGoal;
                        return InkWell(
                          onTap: () => _setGoal(goal),
                          borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), // 【动态圆角】
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.green.withValues(alpha: 0.15) : theme.textColor.withValues(alpha: 0.05),
                              border: Border.all(color: isCurrent ? Colors.green : Colors.transparent),
                              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), // 【动态圆角】
                            ),
                            child: Text(
                              '$goal',
                              style: TextStyle(
                                color: isCurrent ? Colors.green : theme.textColor.withValues(alpha: 0.8),
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    Text('自定义目标', style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              hintText: '输入字数...',
                              hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3)),
                              filled: true,
                              fillColor: theme.textColor.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), borderSide: BorderSide.none), // 【动态圆角】
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            final val = int.tryParse(customController.text);
                            if (val != null) _setGoal(val);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)), // 【动态圆角】
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: const Text('确定', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 60);

    final theme = context.watch<UserProvider>().currentTheme;
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat; // 【动态判断圆角】

    double progress = (widget.currentWordCount / _targetGoal).clamp(0.0, 1.0);
    bool isDone = progress >= 1.0;

    Color activeColor = isDone ? Colors.green : theme.textColor.withValues(alpha: 0.5);

    return InkWell(
      onTap: _showSettingsSheet,
      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0), // 【动态圆角】
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 2.5,
                        backgroundColor: theme.textColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                      );
                    },
                  ),
                  if (isDone)
                    Icon(CupertinoIcons.checkmark_alt, size: 10, color: activeColor),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.currentWordCount}字',
              style: TextStyle(
                fontSize: 12,
                color: isDone ? activeColor : theme.textColor.withValues(alpha: 0.7),
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}