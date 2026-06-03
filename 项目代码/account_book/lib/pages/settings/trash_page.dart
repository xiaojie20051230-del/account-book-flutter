import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger/app_logger.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    AppLogger.i('进入回收站页面', tag: 'TrashPage');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final items = provider.trashItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('回收站 (${items.length})'),
        actions: [
          if (_selected.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore_outlined),
              tooltip: '批量恢复',
              onPressed: () => _batchRestore(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '批量删除',
              onPressed: () => _batchDelete(context),
            ),
          ],
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              tooltip: '清空回收站',
              onPressed: () => _emptyTrash(context),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('回收站为空'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final catProvider = context.read<CategoryProvider>();
                final category = catProvider.getById(item.categoryId);
                final selected = _selected.contains(item.id);

                return Card(
                  color: selected ? theme.colorScheme.primaryContainer : null,
                  child: ListTile(
                    leading: Checkbox(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        });
                      },
                    ),
                    title: Text(category?.name ?? '未分类'),
                    subtitle: Text(
                      '${item.note.isNotEmpty ? '${item.note} · ' : ''}'
                      '删除于 ${_formatDate(item.deletedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore_outlined, size: 20),
                          tooltip: '恢复',
                          onPressed: () {
                            provider.restoreFromTrash(item.id);
                            _selected.remove(item.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_outlined, size: 20),
                          tooltip: '永久删除',
                          onPressed: () => _confirmPermanentDelete(context, item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _batchRestore(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    for (final id in _selected) {
      provider.restoreFromTrash(id);
    }
    setState(() => _selected.clear());
    AppLogger.i('批量恢复', tag: 'TrashPage', data: {'count': _selected.length});
  }

  void _batchDelete(BuildContext context) {
    _confirmAction(context, '批量删除', '确定永久删除选中的 ${_selected.length} 条账单？', () {
      final provider = context.read<TransactionProvider>();
      for (final id in _selected) {
        provider.permanentlyDelete(id);
      }
      setState(() => _selected.clear());
    });
  }

  void _emptyTrash(BuildContext context) {
    _confirmAction(context, '清空回收站', '确定清空回收站？所有账单将被永久删除。', () {
      context.read<TransactionProvider>().emptyTrash();
    });
  }

  void _confirmPermanentDelete(BuildContext context, String id) {
    _confirmAction(context, '永久删除', '确定永久删除此账单？此操作不可撤销。', () {
      context.read<TransactionProvider>().permanentlyDelete(id);
    });
  }

  void _confirmAction(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
