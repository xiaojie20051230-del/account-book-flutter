import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../core/utils/notification_helper.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../models/attachment.dart';
import '../../../providers/attachment_provider.dart';

class AttachmentSection extends StatelessWidget {
  final String transactionId;
  final ValueChanged<List<String>> onChanged;

  const AttachmentSection({
    super.key,
    required this.transactionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final attProvider = context.watch<AttachmentProvider>();
    final atts = attProvider.getByTransaction(transactionId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_file, size: 18),
            const SizedBox(width: 4),
            Text('凭证 (${atts.length}/${AttachmentProvider.maxAttachments})', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            if (atts.length < AttachmentProvider.maxAttachments)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
                onPressed: () => _showPicker(context),
              ),
          ],
        ),
        if (atts.isNotEmpty)
          const SizedBox(height: 8),
        if (atts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: atts.map((a) => _AttachmentThumbnail(attachment: a)).toList(),
          ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选'),
              onTap: () { Navigator.pop(ctx); _pickImage(context); },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('选择文件'),
              onTap: () { Navigator.pop(ctx); _pickFile(context); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    // FilePicker 自行处理权限，无需额外请求
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _addAttachment(context, path);
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _addAttachment(context, path);
  }

  Future<void> _addAttachment(BuildContext context, String filePath) async {
    final provider = context.read<AttachmentProvider>();
    final att = await provider.add(transactionId, filePath);
    if (att != null) {
      onChanged([att.id]);
    }
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;
  const _AttachmentThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _showMenu(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: attachment.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(attachment.filepath), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 28),
                  const SizedBox(height: 4),
                  Text(attachment.filename, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (attachment.isImage) {
      // full screen image preview
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(attachment.filename)),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(attachment.filepath)),
            ),
          ),
        ),
      ));
    } else {
      context.read<AttachmentProvider>().openFile(attachment.filepath);
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(ctx);
                _rename(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _delete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    // BUG-007: 只编辑命名部分，时间前缀和后缀自动保留
    final ext = p.extension(attachment.filename);
    final timePrefix = attachment.filename.split('_').first;
    final oldNamePart = attachment.filename.substring(
      timePrefix.length + 1,
      attachment.filename.length - ext.length,
    );

    final ctrl = TextEditingController(text: oldNamePart);
    final newNamePart = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('重命名（${timePrefix}_xxx$ext）'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: '命名',
            hintText: '例如: 收据',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('确定')),
        ],
      ),
    );
    if (newNamePart == null || newNamePart.isEmpty) return;

    final fullName = '${timePrefix}_$newNamePart$ext';
    final ok = await context.read<AttachmentProvider>().rename(attachment.id, fullName);
    if (!ok && context.mounted) {
      NotificationHelper.showSnackBar(context, '重命名失败，可能存在同名文件');
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await NotificationHelper.confirm(
      context,
      title: '删除凭证',
      message: '确定删除此凭证？',
    );
    if (confirmed) {
      context.read<AttachmentProvider>().delete(attachment.id);
    }
  }
}
