import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/models/book/daily_stats.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isLoading = true;

  DateTime _focusedMonth = DateTime.now();
  Map<int, DailyStats> _calendarStatsMap = {}; // 改为存储完整对象

  int _currentStreak = 0;

  DateTime _selectedDate = DateTime.now();
  DailyStats? _selectedStats; // 当前选中的统计对象

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService();
    _currentStreak = await db.getConsecutiveDays();
    await _loadMonthData();
    _updateSelectedStats();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMonthData() async {
    final db = DatabaseService();
    final monthStatsList = await db.getMonthlyStats(_focusedMonth);

    final map = <int, DailyStats>{};
    for (var s in monthStatsList) {
      map[s.date.day] = s;
    }

    setState(() {
      _calendarStatsMap = map;
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('码字日历')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildStreakHeader(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildHeatmapCalendar(theme),
                const SizedBox(height: 24),
                _buildDayDetail(theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_currentStreak 天',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                _currentStreak > 0 ? '火焰正旺，保持连更！' : '点燃火花，从今天开始！',
                style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCalendar(ThemeData theme) {
    final monthFormat = DateFormat('yyyy年 M月');
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final offsetSlots = firstDayWeekday == 7 ? 0 : firstDayWeekday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(monthFormat.format(_focusedMonth), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((e) => SizedBox(width: 32, child: Center(child: Text(e, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)))))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + offsetSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < offsetSlots) return const SizedBox();

              final day = index - offsetSlots + 1;
              final stats = _calendarStatsMap[day];
              final count = stats?.wordCount ?? 0;
              final isSelected = _selectedDate.year == _focusedMonth.year &&
                  _selectedDate.month == _focusedMonth.month &&
                  _selectedDate.day == day;

              return _buildCalendarDay(theme, day, count, isSelected, stats);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(ThemeData theme, int day, int count, bool isSelected, DailyStats? stats) {
    Color bgColor;
    Color textColor = theme.colorScheme.onSurface;

    if (count == 0) {
      bgColor = Colors.transparent;
    } else if (count < 1000) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.2);
    } else if (count < 3000) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.5);
      textColor = Colors.white;
    } else {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    }

    BoxBorder? border;
    if (isSelected) {
      border = Border.all(color: theme.colorScheme.onSurface, width: 2);
    }

    return GestureDetector(
      onTap: () => _onDayTap(day, stats),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            color: count > 0 ? textColor : theme.colorScheme.onSurfaceVariant,
            fontWeight: (count > 0 || isSelected) ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetail(ThemeData theme) {
    final dateStr = DateFormat('yyyy/MM/dd EEEE', 'zh_CN').format(_selectedDate);
    final count = _selectedStats?.wordCount ?? 0;

    // 获取日志列表
    final logs = _selectedStats?.logs ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('每日详情', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
              const SizedBox(height: 8),

              if (count > 0) ...[
                // 总数显示
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                        '$count',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                    ),
                    const SizedBox(width: 4),
                    const Text('字', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // 【核心修改】动态展示日志列表
                if (logs.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final log = logs[i];
                      final change = log.wordCountChange;
                      final isPositive = change >= 0;
                      return Row(
                        children: [
                          Icon(Icons.edit_note, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${log.timeStr} - ${log.bookTitle} / ${log.chapterTitle}',
                              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                              '${isPositive ? '+' : ''}$change 字',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold
                              )
                          ),
                        ],
                      );
                    },
                  )
                else
                  const Text('暂无详细记录'),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.bedtime, color: theme.colorScheme.outlineVariant),
                    const SizedBox(width: 12),
                    Text('这一天在积蓄力量...', style: TextStyle(color: theme.colorScheme.outline)),
                  ],
                )
              ]
            ],
          ),
        ),
      ],
    );
  }
}
