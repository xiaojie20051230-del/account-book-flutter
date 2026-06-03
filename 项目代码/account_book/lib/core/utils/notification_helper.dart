import 'dart:async';

import 'package:flutter/material.dart';

class NotificationHelper {
  /// SnackBar 提示（带可选撤销操作），5 秒后自动消失
  static void showSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: Text(message),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  /// 确认弹窗，返回 true/false
  static Future<bool> confirm(BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 信息提示弹窗（仅"知道了"按钮）
  static Future<void> info(BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        ],
      ),
    );
  }
}
