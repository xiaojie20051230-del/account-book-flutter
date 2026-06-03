import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger/app_logger.dart';
import '../../core/utils/date_util.dart';
import '../../models/transaction.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    AppLogger.i('打开搜索页', tag: 'SearchPage');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索备注或凭证名...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      provider.search('');
                    },
                  )
                : null,
          ),
          onChanged: (v) {
            setState(() {});
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              final matchedIds = context.read<AttachmentProvider>()
                  .searchFilenames(v).map((a) => a.transactionId).toSet();
              provider.search(v, matchTxIds: matchedIds);
            });
          },
        ),
      ),
      body: _buildResults(theme, provider, catProvider),
    );
  }

  Widget _buildResults(ThemeData theme, TransactionProvider provider, CategoryProvider catProvider) {
    final results = provider.filteredTransactions;
    if (_controller.text.isEmpty) {
      return const Center(child: Text('输入关键字开始搜索'));
    }
    if (results.isEmpty) {
      return const Center(child: Text('未找到匹配的账单'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final t = results[index];
        final category = catProvider.getById(t.categoryId);
        final timeStr = DateUtil.formatDateTime(t.updatedAt ?? t.createdAt);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(category?.icon ?? '📌', style: const TextStyle(fontSize: 20)),
          ),
          title: Text(category?.name ?? '未分类'),
          subtitle: Text('${t.note.isNotEmpty ? '${t.note} · ' : ''}$timeStr', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(
            '${t.isIncome ? "+" : "-"}${t.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: t.isIncome ? Colors.green : Colors.red),
          ),
        );
      },
    );
  }
}
