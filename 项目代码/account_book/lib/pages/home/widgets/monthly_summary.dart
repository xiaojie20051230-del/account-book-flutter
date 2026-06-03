import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction.dart';
import '../../../providers/transaction_provider.dart';

class MonthlySummary extends StatelessWidget {
  final List<Transaction> transactions;

  const MonthlySummary({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 本月结余
            Text(
              (income - expense).toStringAsFixed(2),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: income >= expense ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text('本月结余', style: theme.textTheme.bodySmall),

            const SizedBox(height: 16),

            // 预算进度条
            Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                final budget = provider.monthlyBudget;
                if (budget <= 0) return const SizedBox.shrink();
                final spent = expense;
                final ratio = (spent / budget).clamp(0.0, 1.0);
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('支出 ¥${spent.toStringAsFixed(0)} / ¥${budget.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall),
                        Text('${(ratio * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ratio > 0.9 ? Colors.red : null)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: ratio > 0.9 ? Colors.red : Colors.green,
                        minHeight: 8,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 收入支出概览
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '收入',
                    amount: income,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '支出',
                    amount: expense,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount.toStringAsFixed(2),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
