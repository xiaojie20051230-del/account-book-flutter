import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger/app_logger.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/transaction_provider.dart';
import 'search_page.dart';
import 'widgets/monthly_summary.dart';
import 'widgets/transaction_list.dart';
import '../add_transaction/add_transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _scrollController = ScrollController();
  bool _isFabExtended = true;

  @override
  void initState() {
    super.initState();
    AppLogger.i('进入首页', tag: 'HomePage');
    _scrollController.addListener(() {
      if (_scrollController.offset > 60 && _isFabExtended) {
        setState(() => _isFabExtended = false);
      } else if (_scrollController.offset <= 60 && !_isFabExtended) {
        setState(() => _isFabExtended = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    AppLogger.d('切换月份', tag: 'HomePage', data: {'year': _selectedYear, 'month': _selectedMonth});
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    AppLogger.d('切换月份', tag: 'HomePage', data: {'year': _selectedYear, 'month': _selectedMonth});
  }

  Future<void> _onFabPressed() async {
    AppLogger.i('点击添加账单按钮', tag: 'HomePage');
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (result == true && mounted) {
      AppLogger.i('账单添加成功返回', tag: 'HomePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedYear年$_selectedMonth月'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              AppLogger.i('打开设置', tag: 'HomePage');
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final monthData = provider.getByMonth(_selectedYear, _selectedMonth);

          return RefreshIndicator(
            onRefresh: () async {
              AppLogger.i('下拉刷新', tag: 'HomePage');
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // 月份切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      '$_selectedYear年$_selectedMonth月',
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 搜索栏
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('搜索交易', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 月度汇总
                MonthlySummary(transactions: monthData),

                const SizedBox(height: 24),

                // 账单列表标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('账单明细', style: theme.textTheme.titleMedium),
                    Text('共 ${monthData.length} 笔', style: theme.textTheme.bodySmall),
                  ],
                ),

                const SizedBox(height: 8),

                // 账单列表
                TransactionList(transactions: monthData),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _isFabExtended
          ? FloatingActionButton.extended(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: const Text('记一笔'),
            )
          : FloatingActionButton(
              onPressed: _onFabPressed,
              child: const Icon(Icons.add),
            ),
    );
  }
}
