import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/datasources/hive_category_repo.dart';
import 'data/datasources/hive_transaction_repo.dart';
import 'providers/attachment_provider.dart';
import 'providers/category_provider.dart';
import 'providers/passcode_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'core/logger/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('应用启动', tag: 'Main');

  await Hive.initFlutter();

  final transactionBox = await Hive.openBox('transactions');
  final categoryBox = await Hive.openBox('categories');
  final trashBox = await Hive.openBox('trash');
  final attachmentBox = await Hive.openBox('attachments');
  final settingsBox = await Hive.openBox('settings');

  final transactionRepo = HiveTransactionRepo(transactionBox);
  final categoryRepo = HiveCategoryRepo(categoryBox);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(transactionRepo, trashBox),
        ),
        ChangeNotifierProvider(
          create: (_) => AttachmentProvider(attachmentBox),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryRepo),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = ThemeProvider();
            p.init(settingsBox);
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = PasscodeProvider();
            p.init(settingsBox);
            return p;
          },
        ),
      ],
      child: const AccountBookApp(),
    ),
  );

  AppLogger.i('应用启动完成', tag: 'Main');
}
