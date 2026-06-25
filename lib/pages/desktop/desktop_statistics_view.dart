import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/models/daily_stats.dart';

// 请确认这里的路径与你新建组件的实际路径一致！
import 'package:monet_writer/pages/desktop/components/desktop_crop_dialog.dart';

/// 桌面端：全局码字统计面板 (满血终极版：包含等级与日历大盘)
class DesktopStatisticsView extends StatefulWidget {
  const DesktopStatisticsView({super.key});

  @override
  State<DesktopStatisticsView> createState() => _DesktopStatisticsViewState();
}

class _DesktopStatisticsViewState extends State<DesktopStatisticsView> {
  bool _isLoading = true;
  int _totalBooks = 0;
  int _totalWords = 0;
  int _todayWords = 0;
  int _writingDays = 1;

  final List<int> _weeklyData = [2400, 1200, 4500, 0, 3100, 5200, 800];
  final List<String> _weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  // ================= 日历核心状态 =================
  DateTime _focusedMonth = DateTime.now();
  Map<int, DailyStats> _calendarStatsMap = {};
  DateTime _selectedDate = DateTime.now();
  DailyStats? _selectedStats;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = DatabaseService();
      final books = await db.getAllBooks();
      int totalW = 0;
      for (var b in books) {
        totalW += b.wordCount;
      }

      // 同步加载日历数据
      await _loadMonthData();
      _updateSelectedStats();

      if (mounted) {
        setState(() {
          _totalBooks = books.length;
          _totalWords = totalW;
          _todayWords = _weeklyData.last;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("读取统计失败: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 日历数据调度 ---
  Future<void> _loadMonthData() async {
    final db = DatabaseService();
    final monthStatsList = await db.getMonthlyStats(_focusedMonth);
    final map = <int, DailyStats>{};
    for (var s in monthStatsList) {
      map[s.date.day] = s;
    }
    setState(() => _calendarStatsMap = map);
  }

  void _updateSelectedStats() {
    if (_selectedDate.year == _focusedMonth.year && _selectedDate.month == _focusedMonth.month) {
      _selectedStats = _calendarStatsMap[_selectedDate.day];
    } else {
      _selectedStats = null;
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
      _selectedDate = _focusedMonth;
    });
    _loadMonthData().then((_) => _updateSelectedStats());
  }

  void _onDayTap(int day, DailyStats? stats) {
    setState(() {
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      _selectedStats = stats;
    });
  }

  // --- 图片选择与裁切 ---
  Future<void> _pickAndCropImage(BuildContext context, {required bool isCover}) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      if (!context.mounted) return;

      final croppedPath = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DesktopCropDialog(
          imagePath: path,
          title: isCover ? '调整横幅背景' : '调整头像',
          boxWidth: isCover ? 600.0 : 260.0,
          boxHeight: isCover ? 150.0 : 260.0,
          shape: isCover ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isCover ? BorderRadius.circular(12.0) : null,
        ),
      );

      if (croppedPath != null && context.mounted) {
        if (isCover) {
          await context.read<UserProvider>().updateProfileCoverPath(croppedPath);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 背景已更新')));
        } else {
          await context.read<UserProvider>().updateAvatarPath(croppedPath);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 头像已更新')));
        }
      }
    } catch (e) {
      debugPrint('图片更新失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Container(color: currentTheme.backgroundColor, child: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Container(
      color: currentTheme.backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            children: [
              // ==================== 0. 满血横幅 (新增等级与统计) ====================
              _ProfileBannerHeader(
                onPickBanner: () => _pickAndCropImage(context, isCover: true),
                onPickAvatar: () => _pickAndCropImage(context, isCover: false),
              ),
              const SizedBox(height: 24),

              // ==================== 1. 核心数据网格 ====================
              SizedBox(
                height: 116,
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('累计创作字数', userProvider.totalWords.toString(), CupertinoIcons.text_quote, currentTheme, primaryColor, isFlat)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('今日码字', userProvider.todayWords.toString(), CupertinoIcons.flame_fill, currentTheme, Colors.orangeAccent, isFlat)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('总计作品', _totalBooks.toString(), CupertinoIcons.book_fill, currentTheme, Colors.blueAccent, isFlat)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('累计打卡天数', userProvider.consecutiveDays.toString(), CupertinoIcons.calendar_today, currentTheme, Colors.greenAccent, isFlat)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ==================== 2. 创作趋势图表 ====================
              Text('近 7 日创作趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isFlat ? Colors.transparent : currentTheme.textColor.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
                  border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.05)),
                ),
                child: _buildBarChart(currentTheme, primaryColor, isFlat),
              ),
              const SizedBox(height: 40),

              // ==================== 3. 码字日历大盘 (宽屏双列布局) ====================
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('创作足迹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  const SizedBox(width: 12),
                  Text('点击日期查看当日详情', style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：日历热力图
                  Expanded(
                    flex: 5,
                    child: _buildDesktopCalendar(currentTheme, primaryColor, isFlat),
                  ),
                  const SizedBox(width: 24),
                  // 右侧：单日详情日志
                  Expanded(
                    flex: 4,
                    child: _buildDesktopDayDetail(currentTheme, primaryColor, isFlat),
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // --- 统计小卡片 ---
  Widget _buildStatCard(String title, String value, IconData icon, WritingTheme theme, Color color, bool isFlat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFlat ? Colors.transparent : theme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: theme.textColor.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textColor)),
          ),
        ],
      ),
    );
  }

  // --- 柱状图 ---
  Widget _buildBarChart(WritingTheme theme, Color primary, bool isFlat) {
    final maxVal = _weeklyData.reduce((a, b) => a > b ? a : b);
    final topLimit = maxVal == 0 ? 1000 : maxVal * 1.2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_weeklyData.length, (index) {
        final val = _weeklyData[index];
        final ratio = val / topLimit;
        return _AnimatedBar(value: val, ratio: ratio, label: _weekDays[index], theme: theme, primary: primary, isFlat: isFlat);
      }),
    );
  }

  // ================= 桌面端专属：日历网格 =================
  Widget _buildDesktopCalendar(WritingTheme theme, Color primary, bool isFlat) {
    final monthFormat = DateFormat('yyyy年 M月');
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final offsetSlots = firstDayWeekday == 7 ? 0 : firstDayWeekday;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(CupertinoIcons.chevron_left, color: theme.textColor.withValues(alpha: 0.7)), onPressed: () => _changeMonth(-1)),
              Text(monthFormat.format(_focusedMonth), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
              IconButton(icon: Icon(CupertinoIcons.chevron_right, color: theme.textColor.withValues(alpha: 0.7)), onPressed: () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((e) => Expanded(child: Center(child: Text(e, style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.5))))))
                .toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + offsetSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < offsetSlots) return const SizedBox();
              final day = index - offsetSlots + 1;
              final stats = _calendarStatsMap[day];
              final count = stats?.wordCount ?? 0;
              final isSelected = _selectedDate.year == _focusedMonth.year && _selectedDate.month == _focusedMonth.month && _selectedDate.day == day;

              Color bgColor = Colors.transparent;
              Color textColor = theme.textColor;

              if (count > 0 && count < 1000) {
                bgColor = primary.withValues(alpha: 0.2);
              } else if (count >= 1000 && count < 3000) {
                bgColor = primary.withValues(alpha: 0.5);
                textColor = Colors.white;
              } else if (count >= 3000) {
                bgColor = primary;
                textColor = Colors.white;
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _onDayTap(day, stats),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0),
                      border: isSelected ? Border.all(color: theme.textColor, width: 2) : Border.all(color: theme.textColor.withValues(alpha: 0.05)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: count > 0 ? textColor : theme.textColor.withValues(alpha: 0.4),
                        fontWeight: (count > 0 || isSelected) ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= 桌面端专属：单日详情 =================
  Widget _buildDesktopDayDetail(WritingTheme theme, Color primary, bool isFlat) {
    final dateStr = DateFormat('yyyy / MM / dd  EEEE', 'zh_CN').format(_selectedDate);
    final count = _selectedStats?.wordCount ?? 0;
    final logs = _selectedStats?.logs ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (count > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$count', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(width: 8),
                Text('字', style: TextStyle(fontSize: 16, color: theme.textColor)),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: theme.textColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),

            if (logs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final log = logs[i];
                  final change = log.wordCountChange;
                  final isPositive = change >= 0;
                  return Row(
                    children: [
                      Icon(CupertinoIcons.pen, size: 14, color: primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${log.timeStr}  -  ${log.bookTitle} / ${log.chapterTitle}',
                          style: TextStyle(fontSize: 13, color: theme.textColor.withValues(alpha: 0.8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${isPositive ? '+' : ''}$change',
                            style: TextStyle(fontSize: 12, color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Text('暂无详细操作记录', style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 13)),
          ] else ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.moon_stars_fill, size: 48, color: theme.textColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('这一天在积蓄力量...', style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 14)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final int value;
  final double ratio;
  final String label;
  final WritingTheme theme;
  final Color primary;
  final bool isFlat;

  const _AnimatedBar({required this.value, required this.ratio, required this.label, required this.theme, required this.primary, required this.isFlat});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovered ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: widget.theme.textColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
              child: Text('${widget.value}', style: TextStyle(color: widget.theme.backgroundColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight * widget.ratio;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (!widget.isFlat)
                      Container(width: 40, height: constraints.maxHeight, decoration: BoxDecoration(color: widget.theme.textColor.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(6))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      width: widget.isFlat ? 32 : 40,
                      height: height,
                      decoration: BoxDecoration(
                        color: _isHovered ? widget.primary : widget.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.isFlat ? 4.0 : 6.0), bottom: Radius.circular(widget.isFlat ? 0.0 : 6.0)),
                        border: widget.isFlat ? Border.all(color: widget.primary, width: 1) : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.label, style: TextStyle(fontSize: 12, color: widget.theme.textColor.withValues(alpha: _isHovered ? 0.9 : 0.5), fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ============================================================================
// 毛玻璃横幅 UI 组件 (满血移植了境界体系与数据面板)
// ============================================================================
class _ProfileBannerHeader extends StatefulWidget {
  final VoidCallback onPickBanner;
  final VoidCallback onPickAvatar;

  const _ProfileBannerHeader({required this.onPickBanner, required this.onPickAvatar});

  @override
  State<_ProfileBannerHeader> createState() => _ProfileBannerHeaderState();
}

class _ProfileBannerHeaderState extends State<_ProfileBannerHeader> {
  bool _isHoveringBanner = false;
  bool _isHoveringAvatar = false;

  String _formatNumber(int count) {
    if (count < 10000) return count.toString();
    return '${(count / 10000).toStringAsFixed(1)}万';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;

    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final String? coverPath = userProvider.profileCoverPath;
    final String? avatarPath = userProvider.avatarPath;
    final avatarDominantColor = userProvider.primaryColor;

    // 【修改】：完全脱离组件内写死的逻辑，直接调用引擎中渲染好的头衔
    final levelTitle = userProvider.currentLevelTitle;

    return Container(
      height: 240,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isFlat ? 12.0 : 24.0),
        border: isFlat ? Border.all(color: userProvider.currentTheme.textColor.withValues(alpha: 0.08)) : null,
        boxShadow: isFlat ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHoveringBanner = true),
        onExit: (_) => setState(() => _isHoveringBanner = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPickBanner,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _isHoveringBanner ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuart,
                child: _buildBackgroundLayer(context, coverPath, avatarPath),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),

              AnimatedOpacity(
                opacity: _isHoveringBanner && !_isHoveringAvatar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.photo, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text('点击更换背景图', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 40,
                right: 40,
                bottom: 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ================= 左侧：头像与等级 =================
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringAvatar = true),
                      onExit: (_) => setState(() => _isHoveringAvatar = false),
                      child: GestureDetector(
                        onTap: widget.onPickAvatar,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [avatarDominantColor.withValues(alpha: 0.85), avatarDominantColor.withValues(alpha: 0.15)],
                            ),
                            boxShadow: [BoxShadow(color: avatarDominantColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedScale(
                            scale: _isHoveringAvatar ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scaffoldBgColor,
                                border: Border.all(color: scaffoldBgColor, width: 4),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipOval(
                                    child: (avatarPath != null && avatarPath.isNotEmpty)
                                        ? Image.file(File(avatarPath), fit: BoxFit.cover)
                                        : Icon(CupertinoIcons.person_solid, size: 50, color: avatarDominantColor.withValues(alpha: 0.4)),
                                  ),
                                  AnimatedOpacity(
                                    opacity: _isHoveringAvatar ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.5)),
                                      child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userProvider.nickname ?? '创作者', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          // 【已同步】：这里直接调用全局实时更新的徽章
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [avatarDominantColor.withValues(alpha: 0.8), avatarDominantColor.withValues(alpha: 0.3)]),
                              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              levelTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // ================= 右侧：横向数据展示 (适配宽屏) =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _BannerStatItem(value: userProvider.consecutiveDays.toString(), label: '连续创作(天)'),
                        const SizedBox(width: 24, child: VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8)),
                        _BannerStatItem(value: _formatNumber(userProvider.totalWords), label: '累计字数'),
                        const SizedBox(width: 24, child: VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8)),
                        _BannerStatItem(value: userProvider.todayWords.toString(), label: '今日码字'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundLayer(BuildContext context, String? coverPath, String? avatarPath) {
    if (coverPath != null && coverPath.isNotEmpty) {
      return Image.file(File(coverPath), fit: BoxFit.cover);
    } else if (avatarPath != null && avatarPath.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(avatarPath), fit: BoxFit.cover),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          )
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.6), Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      );
    }
  }
}

// 横幅右侧的数据项子组件
class _BannerStatItem extends StatelessWidget {
  final String value;
  final String label;
  const _BannerStatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}