---
title: Bug Fixes Batch 1
status: Accepted
author: 吕加年
date: 2026-06-03
version: 1.1
revision_history:
  - 1.1 — 重构为标准格式 + 新增 BUG-011~017
  - 1.0 — 初始版本
---

# Bug Fixes Batch 1

BUGFIX-001

---

## 1. 需求

### 1.1 动机

测试阶段发现 17 个问题，涵盖密码锁、主题持久化、UI 溢出、附件命名、搜索、备份恢复、CSV 导出和代码规范。

### 1.2 修复清单

| 编号 | 问题 | 文件 | 严重度 |
|------|------|------|--------|
| BUG-002 | 密码锁不生效：杀进程重开不锁屏 | `lib/app.dart` | 高 |
| BUG-003 | 锁屏页面显示 6 个圆点，用户误以为要输 6 位 | `lib/pages/lock/lock_page.dart` | 中 |
| BUG-004 | 密码时灵时不灵：生命周期状态不同步 | `lib/app.dart` | 高 |
| BUG-005 | 深色模式不持久：重启后回到白色 | `lib/providers/theme_provider.dart`, `lib/main.dart` | 中 |
| BUG-006 | 添加分类对话框 BOTTOM OVERFLOWED | `lib/pages/settings/settings_page.dart` | 中 |
| BUG-007 | 凭证命名无时间前缀，重命名可改完整名 | `lib/pages/add_transaction/widgets/attachment_section.dart` | 中 |
| BUG-008 | 凭证搜索不到 | `lib/providers/attachment_provider.dart`, `lib/pages/home/search_page.dart` | 中 |
| BUG-009 | 低版本 Android 未请求存储权限 | `lib/pages/add_transaction/widgets/attachment_section.dart` | 高 |
| BUG-010 | SnackBar 不自动消失（5 处绕过接口） | 见 §3 | 中 |
| BUG-011 | 备份恢复只恢复第一个文件 | `lib/data/export/backup_manager.dart` | 高 |
| BUG-012 | CSV 导出写分类 ID 而非名称 | `lib/data/export/csv_exporter.dart` | 中 |
| BUG-013 | 备份格式无长度标记，无法分割多文件 | `lib/data/export/backup_manager.dart` | 中 |
| BUG-014 | 生命周期未处理 detached 状态 | `lib/app.dart` | 低 |
| BUG-015 | 附件上限 5 硬编码 | `lib/providers/attachment_provider.dart` | 低 |
| BUG-016 | _pad / _formatTime 跨文件重复 | `lib/core/utils/date_util.dart` | 低 |
| BUG-017 | add_attachment 未判空 | `lib/pages/add_transaction/widgets/attachment_section.dart` | 低 |

---

## 2. UI / 数据流

### 2.1 密码锁流程（BUG-002/003/004/014）

```
App 启动
  → MainShell.initState()
    → passcode.shouldLock? → passcode.lock() → 显示 LockPage
  → 用户输入 4-6 位
    → 验证通过 → passcode.unlock() → 进入主页

App 切后台
  → didChangeAppLifecycleState(paused | inactive | detached)
    → passcode.shouldLock? → passcode.lock() → _showLock = true

LockPage 进入时
  → 显示密码圆点（动态：4-6 个，跟随用户设置长度）
```

### 2.2 附件命名流程（BUG-007）

```
添加附件：
  用户选文件 → copy 到 /attachments/ 目录
  → filename = "20260603_用户命名.jpg"
  → 显示在附件区域

重命名：
  用户长按 → 弹窗（只显示命名部分，不含时间前缀和后缀）
  → 确认 → filename = "20260603_新命名.jpg"
```

### 2.3 搜索流程（BUG-008）

```
用户输入关键字
  → AttachmentProvider.searchFilenames(query)
    → 匹配 filename（时间前缀 + 命名 + 后缀）
    → 返回匹配的附件列表 → 提取 transactionId
  → TransactionProvider.search(query, matchTxIds)
    → 过滤显示匹配账单
```

---

## 3. 组件设计

### 3.1 文件修改清单

| 文件 | 修改项 |
|------|--------|
| `lib/app.dart` | BUG-002/004/014: initState 检查密码、合并 isLocked、加 detached |
| `lib/providers/passcode_provider.dart` | BUG-003: 增加 `pinLength` getter、`restoreLockState` 方法 |
| `lib/providers/theme_provider.dart` | BUG-005: 增加 `init(Box)` 从 Hive 读取、toggle 时写入 |
| `lib/main.dart` | BUG-005: 初始化 ThemeProvider 时传入 settingsBox |
| `lib/pages/lock/lock_page.dart` | BUG-003: 圆点数改为动态（passcode.pinLength） |
| `lib/pages/settings/settings_page.dart` | BUG-006: 对话框加 SingleChildScrollView; BUG-010: SnackBar 改 NotificationHelper; BUG-012: 导出传 categoryMap |
| `lib/pages/home/widgets/transaction_list.dart` | BUG-010: confirmDismiss SnackBar 改 NotificationHelper; BUG-016: 复用工具方法 |
| `lib/pages/add_transaction/add_transaction_page.dart` | BUG-010: SnackBar 改 NotificationHelper |
| `lib/pages/add_transaction/widgets/attachment_section.dart` | BUG-007: 文件名加时间前缀、重命名只改命名部分; BUG-009: 按版本请求权限; BUG-017: add 判空 |
| `lib/providers/attachment_provider.dart` | BUG-008: 增强搜索匹配; BUG-015: 附件上限常量 |
| `lib/data/export/backup_manager.dart` | BUG-011/013: 修复 break、加 4 字节长度头 |
| `lib/data/export/csv_exporter.dart` | BUG-012: 接受 categoryMap 参数 |
| `lib/core/utils/date_util.dart` | BUG-016: 新增 `formatDateTime`、`pad` 方法 |
| `lib/pages/home/search_page.dart` | BUG-008: 搜索逻辑优化; BUG-016: 复用工具方法 |

### 3.2 组件变更详情

#### 3.2.1 PasscodeProvider

```dart
class PasscodeProvider extends ChangeNotifier {
  // BUG-003: 新增 pinLength getter
  int get pinLength => _storedHash != null ? _storedHash!.length : 4;
  // 注意：hash 存储的是固定长度字符串，需要单独存储 PIN 长度
  // 改为在 setPasscode 时保存长度
  int _pinLength = 4;
  int get pinLength => _pinLength;

  bool setPasscode(String passcode) {
    if (passcode.length < 4 || passcode.length > 6) return false;
    if (!RegExp(r'^\d+$').hasMatch(passcode)) return false;
    _pinLength = passcode.length;
    _settingsBox?.put('passcode_length', _pinLength);
    // ... hash and save
  }
}
```

#### 3.2.2 BackupManager

备份格式变更：
```
旧格式: [文件名][0x00][文件内容][文件名][0x00][文件内容]...
新格式: [文件名][0x00][4字节小端长度][文件内容]...
```

#### 3.2.3 CsvExporter

```dart
class CsvExporter {
  final ITransactionRepo _repo;
  final Map<String, Category>? _categoryMap;

  CsvExporter(this._repo, [this._categoryMap]);

  String _catName(String id) => _categoryMap?[id]?.name ?? id;
}
```

---

## 4. 验收标准

| # | 场景 | 操作 | 预期 |
|---|------|------|------|
| 1 | 密码持久锁屏 | 设密码 → 杀进程 → 重开 App | 弹出锁屏页 |
| 2 | 锁屏圆点 | 设 4 位密码 → 锁屏 | 显示 4 个圆点 |
| 3 | 深色模式持久化 | 设深色 → 重开 App | 保持深色 |
| 4 | 添加分类不溢出 | 打开添加分类弹窗 → 选图标 | 内容可滚动，不溢出 |
| 5 | 附件命名格式 | 添加图片 → 查看文件名 | 格式: `20260603_原始名.jpg` |
| 6 | 附件重命名 | 长按 → 重命名 → 输入"收据" | 保存为 `20260603_收据.jpg` |
| 7 | 按时间搜附件 | 搜索 `202606` | 找到对应附件 |
| 8 | 按命名搜附件 | 搜索 `收据` | 找到对应附件 |
| 9 | 低版本权限 | Android 11 设备选图片 | 先弹权限请求弹窗 |
| 10 | 删除 SnackBar | 滑动删除 → 观察 SnackBar | 5 秒后自动消失 |
| 11 | 备份恢复 | 备份 → 恢复 → 重启 App | 所有数据完整 |
| 12 | CSV 导出 | 导出 CSV → 打开 | 分类列显示中文名 |
| 13 | 附件上限常量 | 添加第 6 个附件 | 添加按钮不可用 |

---

## 5. 开放问题

| 问题 | 决定 |
|------|------|
| BUG-007: 时间前缀格式？ | `yyyyMMdd`（如 `20260603_收据.jpg`） |
| BUG-009: 低版本范围？ | API 32 及以下需 `READ_EXTERNAL_STORAGE` |
| BUG-011: 旧备份兼容？ | 新版可读旧版（单文件到末尾），旧版不可读新版 |
| BUG-003: 圆点跟随密码长度？ | 是，动态显示 4-6 个 |
