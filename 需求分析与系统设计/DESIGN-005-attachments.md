---
title: Attachments and Vouchers
status: Accepted
author: 吕加年
date: 2026-06-02
version: 2.0
revision_history:
  - 2.0 — 综合评审后重写
  - 1.0 — 初始版本
---

# Attachments and Vouchers

DESIGN-005

---

## 1. Requirements

### 1.1 Problem

- User cannot attach receipts, invoices, or photos to bills
- No way to search bills by attachment filename
- Delete/recycle flow doesn't cover attachments
- Permission requests scattered, no reusable pattern

### 1.2 Goals

| Requirement | Priority |
|-------------|----------|
| Attach images (jpg, png) to a bill | P0 |
| Attach documents (pdf) to a bill | P1 |
| View attachments (image fullscreen / external open) | P0 |
| Delete attachment with bill (recycle bin) | P0 |
| Search bills by attachment filename | P1 |
| Rename attachment display name | P1 |
| Backup includes attachment files | P1 |
| Reusable permission + notification module | P0 |

### 1.3 Non-goals

- No OCR / AI receipt scanning
- No cloud sync
- Attachments are optional

---

## 2. Data Model

### 2.1 Transaction Model Change

```dart
class Transaction {
  // ... existing fields
  final List<String> attachmentIds;  // NEW
}
```

### 2.2 Attachment Model (NEW)

```dart
class Attachment {
  final String id;              // UUID
  final String transactionId;   // belongs to which bill
  final String filename;        // display name (user can rename)
  final String filepath;        // actual file path on disk
  final String mimeType;        // image/jpeg, application/pdf
  final int sizeBytes;
  final DateTime createdAt;
}
```

### 2.3 File Naming

Format: `{UUID}_{original_filename}`

- UUID prefix prevents filename conflicts
- Display name (`filename`) is user-renameable
- Rename conflict: auto-append ` (1) (2) (3)`
- Search matches both `note` and `filename`

### 2.4 Image vs PDF Handling

| Type | View method | Package |
|------|-------------|---------|
| image/jpeg, image/png | In-app fullscreen (`Image.file()`) | Flutter built-in |
| application/pdf | External app (`OpenFilex.open()`) | open_filex |
| Other formats | External app | open_filex |

### 2.5 Storage

| Data | Storage |
|------|---------|
| Attachment metadata | Hive `attachments` box |
| Actual files | App documents `/attachments/` |
| Relation | `Transaction.attachmentIds` |

---

## 3. 通用模块设计

### 3.1 PermissionHelper

`lib/core/utils/permission_helper.dart`

```dart
class PermissionHelper {
  static Future<bool> request({
    required BuildContext context,
    required dynamic permission,
    required String title,
    required String rationale,
  });
}
```

Reusable for: camera, gallery, storage, fingerprint, notifications.

### 3.2 NotificationHelper

`lib/core/utils/notification_helper.dart`

```dart
class NotificationHelper {
  static void showSnackBar(BuildContext context, String message,
      {String? actionLabel, VoidCallback? onAction,
       Duration duration = const Duration(seconds: 5)});

  static Future<bool> confirm(BuildContext context,
      {required String title, required String message});

  static Future<void> info(BuildContext context,
      {required String title, required String message});
}
```

Reusable for: delete confirm, permission rationale, backup warning, empty trash.

---

## 4. UI / Data Flow

### 4.1 Attachment Flow

```
Adding:
  Add bill page -> tap paperclip icon
  -> Bottom sheet: [拍照] [相册] [文件]
  -> PermissionHelper.request() -> picker opens
  -> File copied to /attachments/{uuid}_{name}
  -> Thumbnail shown (max 5)
  -> On submit: transaction.attachmentIds += [newId]

Viewing:
  Edit page shows thumbnails
  -> tap image -> full screen preview
  -> tap PDF -> OpenFilex.open()

Delete with bill:
  Bill to trash -> attachments follow
  Restore -> both restored
  7-day cleanup -> files deleted
  Permanent delete -> files deleted

Renaming:
  Long press filename -> rename dialog
  Conflict check -> auto-append (1)(2)(3)
```

### 4.2 Search Extension

Search scope: `note` + `attachment filename`

Cross-provider (UI layer orchestrates):

```dart
final matchedTxIds = context.read<AttachmentProvider>()
    .searchFilenames(query)
    .map((a) => a.transactionId)
    .toSet();

final results = context.read<TransactionProvider>()
    .search(query, matchTxIds: matchedTxIds);
```

### 4.3 Backup Flow

```
Settings -> Backup
  -> NotificationHelper.confirm(
      title: '备份附件？',
      message: '备份将包含附件文件(照片/PDF)。'
          '附件文件可能在传输过程中损坏，建议另行保存重要凭证。'
    )
  -> Confirm -> backup Hive + copy attachments/
  -> Cancel -> backup Hive only
```

---

## 5. Component Design

### 5.1 Files

| File | Description |
|------|-------------|
| `lib/core/utils/permission_helper.dart` | NEW |
| `lib/core/utils/notification_helper.dart` | NEW |
| `lib/models/attachment.dart` | NEW |
| `lib/providers/attachment_provider.dart` | NEW |
| `lib/pages/add_transaction/widgets/attachment_section.dart` | NEW |
| `lib/main.dart` | MODIFY: init box |
| `lib/models/transaction.dart` | MODIFY: add attachmentIds |
| `lib/providers/transaction_provider.dart` | MODIFY: search scope |

### 5.2 Packages

| Package | Purpose | Status |
|---------|---------|--------|
| `image_picker` | Camera / gallery | To add |
| `open_filex` | Open PDF externally | ^4.7.0 |
| `file_picker` | File selection | Already added |
| `permission_handler` | Permission detection | To add |

### 5.3 Provider Interface

```dart
class AttachmentProvider {
  Future<Attachment> add(String txId, String sourcePath);
  Future<List<Attachment>> getByTransaction(String txId);
  Future<void> delete(String id);
  Future<void> deleteByTransaction(String txId);
  Future<void> rename(String id, String newName);
  List<Attachment> searchFilenames(String query);
  void openFile(String path);
}
```

### 5.4 Provider 联动规则

两个 Provider 不互相依赖，UI 层负责协调：

| 场景 | UI 层操作 |
|------|----------|
| 永久删除账单 | txProvider.permanentlyDelete() + attProvider.deleteByTransaction() |
| 移入回收站 | txProvider.moveToTrash() (附件 ID 在 trash box 中) |
| 从回收站恢复 | txProvider.restoreFromTrash() (附件一并恢复) |
| 搜索 | attProvider.searchFilenames() -> txProvider.search() |

---

## 6. 回收站联动

| Action | Attachment behavior |
|--------|-------------------|
| Bill moved to trash | Attachments marked as trash (IDs in trash box) |
| Restore from trash | Attachments restored together |
| 7-day auto cleanup | Files deleted from disk |
| Permanent delete | Files deleted immediately |

---

## 7. 权限与隐私

### 7.1 Declarations

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### 7.2 Flow

1. PermissionHelper checks permission
2. No permission -> NotificationHelper shows rationale
3. User confirms -> system request
4. User denies -> no operation, no repeat

### 7.3 Privacy

- Fully offline, zero network requests
- Files stored in app private directory only
- All data cleared on app uninstall

---

## 8. Acceptance Criteria

| # | Scenario | Expected |
|---|----------|---------|
| 1 | Add bill with photo | Saved, thumbnail shows |
| 2 | Add bill with PDF | Listed, opens externally |
| 3 | Full screen image | Displays correctly |
| 4 | Rename attachment | Input, conflict check, saved |
| 5 | Search by filename | Finds matching bill |
| 6 | Delete bill -> attachment to trash | Restore brings both back |
| 7 | Permanent delete -> files removed | Disk + Hive cleaned |
| 8 | Backup with attachments | Confirm dialog, files included |
| 9 | Permission denied | No crash, no operation |

---

## 9. Open Questions

| Question | Decision |
|----------|----------|
| Max attachments per bill? | 5 |
| Need camera capture? | Yes |
| Need full screen preview? | Yes |
| Search scope? | Note + attachment filename |
| Backup include attachments? | Yes, with confirmation |