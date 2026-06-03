import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/logger/app_logger.dart';
import '../models/attachment.dart';

class AttachmentProvider extends ChangeNotifier {
  static const int maxAttachments = 5;

  final Box _box;

  AttachmentProvider(this._box) {
    _load();
  }

  List<Attachment> _attachments = [];

  List<Attachment> get attachments => _attachments;

  List<Attachment> getByTransaction(String txId) {
    return _attachments.where((a) => a.transactionId == txId).toList();
  }

  List<Attachment> searchFilenames(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _attachments.where((a) =>
      a.filename.toLowerCase().contains(q)
    ).toList();
  }

  Attachment? getById(String id) {
    try {
      return _attachments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 添加附件：复制文件到 App 目录，保存元数据
  Future<Attachment?> add(String txId, String sourcePath) async {
    try {
      final attDir = await _getAttachmentsDir();
      final originalName = p.basename(sourcePath);
      final uuid = const Uuid().v4().replaceAll('-', '');
      final storageName = '${uuid}_$originalName';
      final targetPath = '${attDir.path}/$storageName';

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      await sourceFile.copy(targetPath);

      final mimeType = _detectMimeType(originalName);
      final sizeBytes = await sourceFile.length();

      // BUG-007: 文件名加时间前缀
      final now = DateTime.now();
      final timePrefix = '${now.year}${_pad(now.month)}${_pad(now.day)}';
      final nameWithoutExt = p.basenameWithoutExtension(originalName);
      final ext = p.extension(originalName);
      final displayName = '${timePrefix}_$nameWithoutExt$ext';

      final attachment = Attachment(
        id: const Uuid().v4(),
        transactionId: txId,
        filename: displayName,
        filepath: targetPath,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        createdAt: DateTime.now(),
      );

      _attachments.add(attachment);
      await _box.put(attachment.id, attachment.toJson());
      notifyListeners();

      AppLogger.i('附件添加成功', tag: 'AttachmentProvider', data: {'name': originalName, 'txId': txId});
      return attachment;
    } catch (e, stack) {
      AppLogger.e('附件添加失败', tag: 'AttachmentProvider', error: e, stackTrace: stack);
      return null;
    }
  }

  /// 删除单个附件
  Future<void> delete(String id) async {
    try {
      final att = getById(id);
      if (att == null) return;
      await File(att.filepath).delete();
      await _box.delete(id);
      _attachments.removeWhere((a) => a.id == id);
      notifyListeners();
      AppLogger.i('附件删除成功', tag: 'AttachmentProvider', data: {'id': id});
    } catch (e, stack) {
      AppLogger.e('附件删除失败', tag: 'AttachmentProvider', error: e, stackTrace: stack);
    }
  }

  /// 删除某账单的所有附件
  Future<void> deleteByTransaction(String txId) async {
    final ids = _attachments.where((a) => a.transactionId == txId).map((a) => a.id).toList();
    for (final id in ids) {
      await delete(id);
    }
  }

  /// 重命名附件
  Future<bool> rename(String id, String newName) async {
    try {
      final att = getById(id);
      if (att == null) return false;

      // 冲突检测
      final conflict = _attachments.any((a) => a.id != id && a.transactionId == att.transactionId && a.filename == newName);
      if (conflict) return false;

      final updated = att.copyWith(filename: newName);
      _attachments[_attachments.indexWhere((a) => a.id == id)] = updated;
      await _box.put(id, updated.toJson());
      notifyListeners();
      AppLogger.i('附件重命名成功', tag: 'AttachmentProvider', data: {'id': id, 'newName': newName});
      return true;
    } catch (e, stack) {
      AppLogger.e('附件重命名失败', tag: 'AttachmentProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  void openFile(String path) {
    OpenFilex.open(path);
  }

  void _load() {
    try {
      _attachments = _box.values
          .map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}
  }

  Future<Directory> _getAttachmentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final attDir = Directory('${dir.path}/attachments');
    if (!await attDir.exists()) {
      await attDir.create(recursive: true);
    }
    return attDir;
  }

  String _detectMimeType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.jpg': case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.pdf': return 'application/pdf';
      default: return 'application/octet-stream';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
