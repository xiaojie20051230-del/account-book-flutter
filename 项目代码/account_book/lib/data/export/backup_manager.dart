import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logger/app_logger.dart';

class BackupManager {
  static const _backupExtension = '.abk';

  static Future<bool> backup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory(dir.path);

      final backupDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final backupName = '随手记_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}$_backupExtension';
      final backupFile = File('${backupDir.path}/$backupName');

      final buffer = <int>[];
      await for (final entry in hiveDir.list()) {
        if (entry is File && (entry.path.endsWith('.hive') || entry.path.endsWith('.lock'))) {
          final name = entry.uri.pathSegments.last;
          final bytes = await entry.readAsBytes();
          buffer.addAll(name.codeUnits);
          buffer.add(0);
          // BUG-011/013: 4 字节小端长度前缀
          buffer.addAll(_int32toBytes(bytes.length));
          buffer.addAll(bytes);
        }
      }
      await backupFile.writeAsBytes(buffer);

      await Share.shareXFiles([XFile(backupFile.path)], text: '随手记备份');

      AppLogger.i('备份成功', tag: 'BackupManager');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('备份失败', tag: 'BackupManager', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> restore() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory(dir.path);

      // 清空现有 Hive 文件
      await for (final entry in hiveDir.list()) {
        if (entry is File && (entry.path.endsWith('.hive') || entry.path.endsWith('.lock'))) {
          await entry.delete();
        }
      }

      // BUG-011/013: 按长度头分割多文件
      final tempDir = Directory('${hiveDir.path}/.restore_tmp');
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      await tempDir.create();

      int pos = 0;
      while (pos < bytes.length) {
        final nameEnd = bytes.indexOf(0, pos);
        if (nameEnd == -1) break;
        final name = String.fromCharCodes(bytes.sublist(pos, nameEnd));
        pos = nameEnd + 1;

        // BUG-019: 只允许安全文件名
        if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(name)) continue;

        // BUG-020: 兼容旧版无长度头格式
        if (pos + 4 > bytes.length) {
          // 旧版格式：剩余内容作为文件数据
          await File('${tempDir.path}/$name').writeAsBytes(bytes.sublist(pos));
          break;
        }
        final contentLen = _bytesToInt32(bytes.sublist(pos, pos + 4));
        pos += 4;

        final contentEnd = pos + contentLen;
        if (contentEnd > bytes.length) break;
        final content = bytes.sublist(pos, contentEnd);
        pos = contentEnd;

        await File('${tempDir.path}/$name').writeAsBytes(content);
      }

      // BUG-026: 全部写入临时目录成功后再替换
      await for (final entry in tempDir.list()) {
        if (entry is File) {
          final target = File('${hiveDir.path}/${entry.uri.pathSegments.last}');
          await entry.copy(target.path);
        }
      }
      await tempDir.delete(recursive: true);

      AppLogger.i('恢复成功', tag: 'BackupManager');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('恢复失败', tag: 'BackupManager', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  static List<int> _int32toBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  static int _bytesToInt32(List<int> bytes) {
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }
}
