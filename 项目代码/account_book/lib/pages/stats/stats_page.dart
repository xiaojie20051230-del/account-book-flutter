import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logger/app_logger.dart';
import '../../../models/transaction.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<Transaction> _lastAll = const [];
  List<Transaction> _cachedMonthData = const [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = context.watch<TransactionProvider>().transactions;

    // BUG-022: 缓存月度数据，避免每次 build 重复遍历
    if (transactions != _lastAll) {
      _lastAll = transactions;
      _cachedMonthData = transactions
          .where((t) => t.date.year == _selectedYear && t.date.month == _selectedMonth)
          .toList();
    }
    final monthData = _cachedMonthData;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedYear年$_selectedMonth月 统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; } else { _selectedMonth--; }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; } else { _selectedMonth++; }
            }),
          ),
        ],
      ),
      body: monthData.isEmpty
          ? const Center(child: Text('暂无数据'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CategoryPieChart(transactions: monthData),
                const SizedBox(height: 24),
                _MonthlyBarChart(transactions: transactions, year: _selectedYear),
                const SizedBox(height: 24),
                _TrendLineChart(transactions: transactions),
              ],
            ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  const _CategoryPieChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catProvider = context.watch<CategoryProvider>();
    final expenses = transactions.where((t) => !t.isIncome).toList();
    if (expenses.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(32), child: Text('本月无支出')));

    final total = expenses.fold(0.0, (s, t) => s + t.amount.abs());
    final grouped = <String, double>{};
    for (final t in expenses) {
      grouped[t.categoryId] = (grouped[t.categoryId] ?? 0) + t.amount.abs();
    }

    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.blue, Colors.purple, Colors.teal, Colors.pink, Colors.indigo];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('支出分类占比', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: grouped.entries.toList().asMap().entries.map((e) =>
                    PieChartSectionData(
                      value: e.value.value,
                      title: '${(e.value.value / total * 100).toStringAsFixed(0)}%',
                      color: colors[e.key % colors.length],
                      radius: 50,
                    )
                  ).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: grouped.entries.toList().asMap().entries.map((e) {
                final cat = catProvider.getById(e.value.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('${cat?.name ?? '未知'} ¥${e.value.value.toStringAsFixed(1)}', style: theme.textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final int year;
  const _MonthlyBarChart({required this.transactions, required this.year});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 一次性计算 12 个月数据，避免多次遍历
    final monthlyData = List.generate(12, (i) {
      final month = i + 1;
      final monthData = transactions.where((t) => t.date.year == year && t.date.month == month).toList();
      final income = monthData.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final expense = monthData.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());
      return (income, expense);
    });
    final maxY = monthlyData.fold(0.0, (max, d) => (d.$1 + d.$2) > max ? (d.$1 + d.$2) : max) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$year 年收支趋势', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY : 1,
                  barGroups: List.generate(12, (i) {
                    final (income, expense) = monthlyData[i];
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: income, color: Colors.green, width: 8),
                      BarChartRodData(toY: expense, color: Colors.red, width: 8),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('${v.toInt() + 1}月', style: const TextStyle(fontSize: 10)))),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(_formatAxisNumber(v.toInt()), style: const TextStyle(fontSize: 10)),
                    )),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: Colors.green, label: '收入'),
                const SizedBox(width: 24),
                _Legend(color: Colors.red, label: '支出'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  final List<Transaction> transactions;
  const _TrendLineChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final List<double> monthlyTotals = List.filled(6, 0);
    for (int i = 0; i < 6; i++) {
      final dt = DateTime(now.year, now.month - i, 1);
      final m = dt.month;
      final y = dt.year;
      final total = transactions
          .where((t) => t.date.year == y && t.date.month == m)
          .fold(0.0, (s, t) => s + t.amount.abs());
      monthlyTotals[5 - i] = total;
    }

    final maxY = monthlyTotals.reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('近 6 月趋势', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY > 0 ? maxY : 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(6, (i) => FlSpot(i.toDouble(), monthlyTotals[i])),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withAlpha(40)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= 6) return const Text('');
                        final dt = DateTime(now.year, now.month - (5 - idx), 1);
                        return Text('${dt.month}月', style: const TextStyle(fontSize: 10));
                      },
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(_formatAxisNumber(v.toInt()), style: const TextStyle(fontSize: 10)),
                    )),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

/// 格式化坐标轴数字：1000 → 1k, 1000000 → 1M
String _formatAxisNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}
