import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionHelper {
  /// 检查权限 → 弹窗说明 → 发起系统请求
  /// [rationale] 权限说明文案
  /// 返回 true=已授权, false=拒绝
  static Future<bool> request({
    required BuildContext context,
    required ph.Permission permission,
    required String title,
    required String rationale,
  }) async {
    if (await permission.isGranted) return true;

    final shouldShow = await permission.shouldShowRequestRationale;
    if (shouldShow) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(rationale),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不了')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('知道了')),
          ],
        ),
      );
      if (proceed != true) return false;
    }

    final result = await permission.request();
    return result.isGranted;
  }
}
