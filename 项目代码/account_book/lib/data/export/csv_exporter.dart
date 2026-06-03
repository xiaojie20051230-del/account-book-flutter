import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logger/app_logger.dart';
import '../../core/utils/date_util.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../repositories/itransaction_repo.dart';

class CsvExporter {
  CsvExporter(this._repo, [this._categoryMap]);

  final ITransactionRepo _repo;
  final Map<String, Category>? _categoryMap;

  Future<bool> exportAndShare() async {
    try {
      final transactions = await _repo.getAll();

      final csv = _buildCsv(transactions);
      final file = await _writeTempFile(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '随手记账单导出',
      );

      AppLogger.i('CSV 导出成功', tag: 'CsvExporter', data: {'count': transactions.length});
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('CSV 导出失败', tag: 'CsvExporter', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  String _buildCsv(List<Transaction> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('日期,类型,分类,金额,备注');

    for (final t in transactions) {
      // BUG-012: 显示分类名称而非 ID
      final catName = _categoryMap?[t.categoryId]?.name ?? t.categoryId;
      buffer.writeln('${_escapeCsv(DateUtil.formatDate(t.date))},'
          '${_escapeCsv(t.isIncome ? "收入" : "支出")},'
          '${_escapeCsv(catName)},'
          '${t.amount.toStringAsFixed(2)},'
          '${_escapeCsv(t.note)}');
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<File> _writeTempFile(String content) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename = '随手记_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
    return file;
  }
}
