import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger/app_logger.dart';
import '../../core/utils/notification_helper.dart';
import '../../data/export/backup_manager.dart';
import '../../data/export/csv_exporter.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/passcode_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import 'trash_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i('进入设置页面', tag: 'SettingsPage');

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '分类管理'),
          _CategoryManager(),

          const Divider(),

          const _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('回收站'),
            subtitle: Text('${context.watch<TransactionProvider>().trashItems.length} 条 · 7 天后自动清除'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashPage())),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导出数据'),
            subtitle: const Text('将账单数据导出为 CSV 并分享'),
            onTap: () async {
              AppLogger.i('点击导出数据', tag: 'SettingsPage');
              final repo = context.read<TransactionProvider>().repo;
              final catProvider = context.read<CategoryProvider>();
              final catMap = {for (final c in catProvider.categories) c.id: c};
              final exporter = CsvExporter(repo, catMap);
              final success = await exporter.exportAndShare();
              if (context.mounted) {
                NotificationHelper.showSnackBar(context, success ? 'CSV 已生成，选择分享方式' : '导出失败');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('备份数据'),
            subtitle: const Text('将数据备份为 .abk 文件'),
            onTap: () async {
              final success = await BackupManager.backup();
              if (context.mounted) {
                NotificationHelper.showSnackBar(context, success ? '备份已生成' : '备份失败');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('恢复数据'),
            subtitle: const Text('从 .abk 文件恢复'),
            onTap: () async {
              final success = await BackupManager.restore();
              if (context.mounted) {
                NotificationHelper.showSnackBar(context, success ? '恢复成功，请重启 App' : '恢复失败或已取消');
              }
            },
          ),
          const Divider(),
          const _SectionHeader(title: '预算'),
          _BudgetSetting(),
          const Divider(),
          const _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().mode == ThemeMode.dark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: '安全'),
          _PasscodeSetting(),
        ],
      ),
    );
  }
}

class _BudgetSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: const Text('每月预算'),
      subtitle: const Text('设置月度支出上限'),
      trailing: TextButton(
        onPressed: () => _showBudgetDialog(context),
        child: Text('¥${context.watch<TransactionProvider>().monthlyBudget.toStringAsFixed(0)}'),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置月度预算'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '预算金额', border: OutlineInputBorder(), prefixText: '¥ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) {
                context.read<TransactionProvider>().monthlyBudget = v;
                Navigator.pop(ctx);
              } else {
                NotificationHelper.showSnackBar(context, '请输入有效的预算金额');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _PasscodeSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasscodeProvider>();
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(provider.hasPasscode ? '修改密码' : '设置密码'),
      subtitle: Text(provider.hasPasscode ? '已启用' : '未设置'),
      trailing: provider.hasPasscode
          ? TextButton(
              onPressed: () => _showRemoveDialog(context),
              child: const Text('关闭', style: TextStyle(color: Colors.red)),
            )
          : null,
      onTap: () => _showSetDialog(context),
    );
  }

  void _showSetDialog(BuildContext context) {
    _showPasscodeDialog(context, isRemove: false);
  }

  void _showRemoveDialog(BuildContext context) {
    _showPasscodeDialog(context, isRemove: true);
  }

  void _showPasscodeDialog(BuildContext context, {required bool isRemove}) {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRemove ? '关闭密码' : '设置密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: isRemove ? '输入当前密码' : '输入新密码',
                border: const OutlineInputBorder(),
              ),
            ),
            if (!isRemove) ...[
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final pass = ctrl.text.trim();
              final provider = ctx.read<PasscodeProvider>();
              if (isRemove) {
                if (provider.remove(pass)) {
                  NotificationHelper.showSnackBar(ctx, '密码已关闭');
                  Navigator.pop(ctx);
                } else {
                  NotificationHelper.showSnackBar(ctx, '密码错误');
                }
              } else {
                if (pass != confirmCtrl.text.trim()) {
                  NotificationHelper.showSnackBar(ctx, '两次密码不一致');
                  return;
                }
                if (provider.setPasscode(pass)) {
                  NotificationHelper.showSnackBar(ctx, '密码已设置');
                  Navigator.pop(ctx);
                } else {
                  NotificationHelper.showSnackBar(ctx, '密码必须是 4-6 位数字');
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _CategoryManager extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final customCats = catProvider.categories.where((c) => !c.isPreset).toList();

    return Column(
      children: [
        // 支出预置分类
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('支出分类', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ),
        ...catProvider.expenses.where((c) => c.isPreset).map((c) => ListTile(
          leading: Text(c.icon, style: const TextStyle(fontSize: 24)),
          title: Text(c.name),
          trailing: const Icon(Icons.lock_outline, size: 16),
        )),
        // 收入预置分类
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('收入分类', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ),
        ...catProvider.incomes.where((c) => c.isPreset).map((c) => ListTile(
          leading: Text(c.icon, style: const TextStyle(fontSize: 24)),
          title: Text(c.name),
          trailing: const Icon(Icons.lock_outline, size: 16),
        )),
        // 自定义分类
        if (customCats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('自定义分类', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          ...customCats.map((c) => ListTile(
            leading: Text(c.icon, style: const TextStyle(fontSize: 24)),
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final ok = await NotificationHelper.confirm(
                  context,
                  title: '删除分类',
                  message: '确定删除分类「${c.name}」？已有账单不受影响。',
                );
                if (ok) {
                  AppLogger.i('删除自定义分类', tag: 'SettingsPage', data: {'name': c.name});
                  catProvider.delete(c.id);
                }
              },
            ),
          )),
        ],
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('添加自定义分类'),
          onTap: () => _showAddCategoryDialog(context),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedIcon = '📌';
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('支出')),
                  ButtonSegment(value: true, label: Text('收入')),
                ],
                selected: {isIncome},
                onSelectionChanged: (v) => setDialogState(() => isIncome = v.first),
              ),
              const SizedBox(height: 12),
              Text('选择图标', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: ['🍽️', '🚌', '🛒', '🎮', '🏠', '📚', '💊', '💰', '💼', '🧧', '🎬', '✈️', '🐱', '🎁', '📌']
                    .map((icon) => ChoiceChip(
                      label: Text(icon),
                      selected: selectedIcon == icon,
                      onSelected: (_) => setDialogState(() => selectedIcon = icon),
                    ))
                    .toList(),
              ),
            ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final cat = Category.create(
                  name: nameCtrl.text.trim(),
                  icon: selectedIcon,
                  isIncome: isIncome,
                );
                context.read<CategoryProvider>().add(cat);
                AppLogger.i('添加自定义分类完成', tag: 'SettingsPage', data: {'name': cat.name});
                Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
