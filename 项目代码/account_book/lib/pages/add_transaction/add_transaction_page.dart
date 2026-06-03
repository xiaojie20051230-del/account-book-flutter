import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/logger/app_logger.dart';
import '../../core/utils/notification_helper.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import 'widgets/attachment_section.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? editTransaction;

  const AddTransactionPage({super.key, this.editTransaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _categoryError;
  String _tempTxId = const Uuid().v4();

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;
    if (edit != null) {
      _isIncome = edit.isIncome;
      _amountController.text = edit.amount.abs().toString();
      _noteController.text = edit.note;
      _selectedDate = edit.date;
    }
    AppLogger.i('${_isEditing ? "编辑" : "添加"}账单页面', tag: 'AddTransactionPage');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      AppLogger.d('选择日期', tag: 'AddTransactionPage', data: {'date': picked.toString()});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _categoryError = '请选择分类');
      return;
    }

    setState(() => _isSubmitting = true);
    AppLogger.i('提交账单', tag: 'AddTransactionPage');

    try {
      final amount = double.parse(_amountController.text);
      final finalAmount = _isIncome ? amount.abs() : -amount.abs();

      final transactionRepo = context.read<TransactionProvider>();

      if (_isEditing) {
        final updated = widget.editTransaction!.copyWith(
          amount: finalAmount,
          categoryId: _selectedCategory!.id,
          note: _noteController.text,
          date: _selectedDate,
        );
        await transactionRepo.update(updated);
        AppLogger.i('账单更新成功', tag: 'AddTransactionPage');
      } else {
        final transaction = Transaction(
            id: _tempTxId,
            amount: finalAmount,
            categoryId: _selectedCategory!.id,
            note: _noteController.text,
            date: _selectedDate,
            createdAt: DateTime.now(),
          );
          await transactionRepo.add(transaction);
        AppLogger.i('账单添加成功', tag: 'AddTransactionPage');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, stackTrace) {
      AppLogger.e('提交账单失败', tag: 'AddTransactionPage', error: e, stackTrace: stackTrace);
      if (mounted) {
        NotificationHelper.showSnackBar(context, '保存失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final categories = _isIncome ? catProvider.incomes : catProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑账单' : '添加账单'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 收入/支出切换
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('支出')),
                ButtonSegment(value: true, label: Text('收入')),
              ],
              selected: {_isIncome},
              onSelectionChanged: (v) {
                setState(() {
                  _isIncome = v.first;
                  _selectedCategory = null;
                  _categoryError = null;
                });
              },
            ),

            const SizedBox(height: 24),

            // 金额输入
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入金额';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return '请输入有效金额';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 日期选择
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '日期',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 分类选择
            Text('选择分类', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = _selectedCategory?.id == cat.id;
                return ChoiceChip(
                  label: Text('${cat.icon} ${cat.name}'),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                      _categoryError = null;
                    });
                    AppLogger.d('选择分类', tag: 'AddTransactionPage', data: {'name': cat.name});
                  },
                );
              }).toList(),
            ),
            if (_categoryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _categoryError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),

            // 备注
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // 凭证
            AttachmentSection(
              transactionId: _isEditing ? widget.editTransaction!.id : _tempTxId,
              onChanged: (_) {},
            ),

            const SizedBox(height: 24),

            // 提交按钮
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '保存修改' : '添加账单'),
            ),
          ],
        ),
      ),
    );
  }
}
