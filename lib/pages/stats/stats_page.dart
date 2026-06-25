import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/models/daily_stats.dart';
import 'package:monet_writer/services/database_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _isLoading = true;

  // 图表数据
  List<DailyStats> _weeklyData = [];

  // 核心指标
  int _peakCount = 0;
  String _peakDateStr = '-';
  int _avgCount = 0;
  int _totalActiveDays = 0;
  int _weeklyTotal = 0; // 本周总计

  // 本月数据
  int _monthTotal = 0;
  int _monthActiveDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService();

    // 1. 获取周数据
    final weeklyRaw = await db.getWeeklyStats();
    _processWeeklyData(weeklyRaw);
    _weeklyTotal = weeklyRaw.fold(0, (sum, e) => sum + e.wordCount);

    // 2. 获取峰值
    final peak = await db.getPeakRecord();
    if (peak != null) {
      _peakCount = peak.wordCount;
      _peakDateStr = DateFormat('MM/dd').format(peak.date);
    }

    // 3. 获取总活跃天数 & 计算日均
    _totalActiveDays = await db.getActiveDaysCount();
    final totalWords = await db.getTotalWordCount();
    if (_totalActiveDays > 0) {
      _avgCount = (totalWords / _totalActiveDays).round();
    }

    // 4. 本月数据
    final monthStats = await db.getCurrentMonthStats();
    _monthTotal = monthStats.fold(0, (sum, item) => sum + item.wordCount);
    _monthActiveDays = monthStats.where((e) => e.wordCount > 0).length;

    if (mounted) setState(() => _isLoading = false);
  }

  void _processWeeklyData(List<DailyStats> raw) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final targetDate = today.subtract(Duration(days: i));

      final record = raw.where((e) =>
      e.date.year == targetDate.year &&
          e.date.month == targetDate.month &&
          e.date.day == targetDate.day
      ).firstOrNull;

      if (record != null) {
        _weeklyData.add(record);
      } else {
        _weeklyData.add(DailyStats()..date = targetDate..wordCount = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTrendChart(context),
          const SizedBox(height: 24),
          _buildKeyMetrics(context),
          const SizedBox(height: 24),
          _buildMonthlySummary(context),
        ],
      ),
    );
  }

  // --- 1. 趋势图表 (Bar Chart) ---
  Widget _buildTrendChart(BuildContext context) {
    final theme = Theme.of(context);

    int maxVal = 100;
    for (var s in _weeklyData) {
      if (s.wordCount > maxVal) maxVal = s.wordCount;
    }

    // 【核心修复】将 Container 替换为 Card，使其自动读取全局主题 (扁平风/现代风)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('近 7 天趋势', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_weeklyData.isNotEmpty)
                  Text(
                      '今日: ${_weeklyData.last.wordCount}',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 柱状图主体
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weeklyData.map((stat) {
                  final isToday = stat.date.day == DateTime.now().day && stat.date.month == DateTime.now().month;
                  final heightFactor = stat.wordCount / maxVal;
                  final dateLabel = DateFormat('dd').format(stat.date);

                  return Expanded(
                    child: Tooltip(
                      message: '${stat.wordCount} 字\n${DateFormat('MM/dd').format(stat.date)}',
                      triggerMode: TooltipTriggerMode.tap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: heightFactor == 0 ? 0.02 : heightFactor,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                                  // 内部柱状图圆角稍作收敛，适配两种风格
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: isToday ? theme.colorScheme.primary : theme.colorScheme.outline
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. 核心指标看板 (Grid) ---
  Widget _buildKeyMetrics(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricCard(
          icon: Icons.emoji_events_outlined,
          label: '单日峰值',
          value: _peakCount.toString(),
          subText: _peakDateStr,
          color: Colors.amber,
        ),
        _MetricCard(
          icon: Icons.speed,
          label: '日均产量',
          value: _avgCount.toString(),
          subText: '平均水平',
          color: Colors.blue,
        ),
        _MetricCard(
          icon: Icons.date_range,
          label: '本周总计',
          value: _weeklyTotal.toString(),
          subText: '近7天',
          color: Colors.green,
        ),
        _MetricCard(
          icon: Icons.edit_calendar,
          label: '打卡天数',
          value: _totalActiveDays.toString(),
          subText: '总活跃',
          color: Colors.purple,
        ),
      ],
    );
  }

  // --- 3. 本月概览 ---
  Widget _buildMonthlySummary(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // 【核心修复】同样将 Container 替换为 Card
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.month}月 概览', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SummaryRow(label: '本月累计字数', value: '$_monthTotal 字'),
            const Divider(height: 24),
            _SummaryRow(label: '本月打卡天数', value: '$_monthActiveDays 天'),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subText;
  final Color color;

  const _MetricCard({
    required this.icon, required this.label, required this.value,
    required this.subText, required this.color
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 【核心修复】去除硬编码圆角和颜色，拥抱全局 CardTheme
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(subText, style: TextStyle(fontSize: 10, color: theme.colorScheme.outlineVariant)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}