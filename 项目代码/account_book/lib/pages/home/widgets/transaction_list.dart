import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/notification_helper.dart';
import '../../../models/transaction.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../add_transaction/add_transaction_page.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('暂无账单记录', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      final key = DateUtil.formatDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedKeys.map((date) {
        final items = grouped[date]!;
        final dayTotal = items.fold(0.0, (double sum, t) => sum + t.amount);
        return _DateGroup(
          date: date,
          total: dayTotal,
          items: items,
        );
      }).toList(),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final double total;
  final List<Transaction> items;

  const _DateGroup({
    required this.date,
    required this.total,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catProvider = context.watch<CategoryProvider>();
    final dailyIncome = items.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final dailyExpense = items.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // 比例条
              _RatioBar(income: dailyIncome, expense: dailyExpense),
              const SizedBox(width: 8),
              Expanded(
                child: Text(date, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                '${total >= 0 ? "+" : ""}${total.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: total >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        ...items.map((t) => _TransactionTile(transaction: t, catProvider: catProvider)),
      ],
    );
  }
}

class _RatioBar extends StatelessWidget {
  final double income;
  final double expense;
  const _RatioBar({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    if (total == 0) return const SizedBox(width: 4, height: 16);

    final incomeRatio = income / total;
    final expenseRatio = expense / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 4,
        height: 16,
        child: Column(
          children: [
            if (expense > 0)
              Flexible(flex: ((expenseRatio * 100).toInt()).clamp(1, 100), child: Container(color: Colors.red)),
            if (income > 0)
              Flexible(flex: ((incomeRatio * 100).toInt()).clamp(1, 100), child: Container(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final CategoryProvider catProvider;

  const _TransactionTile({
    required this.transaction,
    required this.catProvider,
  });

  @override
  Widget build(BuildContext context) {
    final category = catProvider.getById(transaction.categoryId);
    final timeLabel = transaction.updatedAt ?? transaction.createdAt;
    final timeStr = DateUtil.formatDateTime(timeLabel);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        AppLogger.i('滑动删除-移入回收站', tag: 'TransactionList', data: {'id': transaction.id});
        final provider = context.read<TransactionProvider>();
        await provider.moveToTrash(transaction);
        if (context.mounted) {
          NotificationHelper.showSnackBar(
            context,
            '已删除 "${category?.name ?? '未分类'} ${transaction.amount.abs().toStringAsFixed(2)}"',
            actionLabel: '撤销',
            onAction: () {
              AppLogger.i('撤销删除', tag: 'TransactionList', data: {'id': transaction.id});
              provider.restoreFromTrash(transaction.id);
            },
          );
        }
        return true;
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(category?.icon ?? '📌', style: const TextStyle(fontSize: 20)),
          ),
          title: Text(category?.name ?? '未分类'),
          subtitle: Text(
            '${transaction.note.isNotEmpty ? '${transaction.note} · ' : ''}$timeStr',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${transaction.isIncome ? "+" : "-"}${transaction.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: transaction.isIncome ? Colors.green : Colors.red,
            ),
          ),
          onTap: () async {
            AppLogger.i('编辑账单', tag: 'TransactionList', data: {'id': transaction.id});
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionPage(editTransaction: transaction),
              ),
            );
            if (result == true && context.mounted) {
              AppLogger.i('账单编辑成功', tag: 'TransactionList');
            }
          },
        ),
      ),
    );
  }
}
