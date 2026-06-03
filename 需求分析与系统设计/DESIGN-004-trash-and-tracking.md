---
title: Trash and Modification Tracking
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# Trash and Modification Tracking

DESIGN-004

---

## 1. 需求

### 1.1 问题

- 用户滑动或长按删除账单后，没有挽回机会
- 编辑账单后，无法追踪最后修改时间
- 已删除的账单永久消失，无法回溯

### 1.2 目标

| 需求 | 优先级 |
|------|--------|
| 删除的账单移入回收站，7 天内可恢复 | P0 |
| 编辑时记录最后修改时间 `updatedAt` | P0 |
| 设置页可查看回收站，支持恢复和永久删除 | P0 |
| 编辑不产生旧版本备份，直接覆盖 | P1 |

### 1.3 非目标

- 不实现完整版本历史（每次编辑生成一个修订版）
- 回收站内的数据不计入 CSV 导出
- 回收站清理只在 App 启动时执行，不做后台定时任务

---

## 2. UI / 数据流

### 2.1 用户流程

```
删除流程:
  滑动/长按账单 → 确认弹窗("移入回收站? 7天可恢复")
  → [移入回收站] → 列表移除，SnackBar 显示"已删除"

撤销流程:
  SnackBar [撤销] → 从回收站恢复到列表

回收站页面:
  设置 → 回收站 → 列表显示已删账单
  → [恢复] → 回到列表
  → [永久删除] → 彻底移除

修改流程:
  编辑账单 → 保存 → 直接覆盖，记录 updatedAt
```

### 2.2 界面

```
账单列表项:
  餐饮          -29.90
  🍽️ 午餐 · 今天 12:30    ← 显示 updatedAt 或 createdAt

回收站页:
  ← 回收站             [清空回收站]

  餐饮     -29.90    [恢复] [永久删除]
    删除于 06-01

  共 1 条 · 7 天后自动清除
```

---

## 3. 组件设计

### 3.1 数据模型

```dart
// Transaction 增加 updatedAt
class Transaction {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;  // 新增
}

// TrashItem 新建
class TrashItem {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime deletedAt;
}
```

### 3.2 存储

| 数据 | 存储方式 |
|------|---------|
| 活跃账单 | Hive `transactions` box |
| 回收站 | Hive `trash` box（独立 box） |
| 自动清理 | App 启动时检查 deletedAt，超 7 天删除 |

### 3.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/models/transaction.dart` | 修改 — 增加 `updatedAt` 字段 |
| `lib/models/trash_item.dart` | 新建 — TrashItem 模型 |
| `lib/providers/transaction_provider.dart` | 修改 — 增加回收站方法、updatedAt 更新 |
| `lib/pages/home/widgets/transaction_list.dart` | 修改 — 显示时间、删除改为移入回收站 |
| `lib/pages/settings/trash_page.dart` | 新建 — 回收站管理页面 |
| `lib/pages/settings/settings_page.dart` | 修改 — 增加回收站入口 |
| `lib/main.dart` | 修改 — 初始化 trash box |

### 3.4 Provider 接口

```dart
// 新增方法
Future<void> moveToTrash(Transaction tx);    // 移入回收站
Future<void> restoreFromTrash(String id);    // 恢复
Future<void> permanentlyDelete(String id);   // 永久删除
List<TrashItem> get trashItems;              // 回收站列表
```

---

## 4. 验收标准

| # | 场景 | 操作 | 预期结果 |
|---|------|------|---------|
| 1 | 删除账单 | 滑动或长按 → 确认 | 账单移至回收站，列表消失，SnackBar 出现 |
| 2 | 撤销删除 | 点 SnackBar [撤销] | 账单回到列表 |
| 3 | 回收站查看 | 设置 → 回收站 | 显示所有已删账单，含删除时间 |
| 4 | 恢复 | 回收站点 [恢复] | 账单回到列表，回收站移除该项 |
| 5 | 永久删除 | 回收站点 [永久删除] | 该项从回收站移除 |
| 6 | 修改时间 | 编辑账单 → 保存 | `updatedAt` 更新为当前时间 |
| 7 | 时间显示 | 查看列表 | subtitle 显示"· 今天 12:30" |
| 8 | 7 天清理 | 修改系统时间到 7 天后 → 重启 App | 过期回收站项自动清除 |
| 9 | 编辑不产生旧版本 | 编辑后查看回收站 | 回收站没有旧版本记录 |

---

## 5. 开放问题

| 问题 | 结论 |
|------|------|
| 回收站是否需要批量功能？ | **是**，支持全选/批量恢复/批量删除 |
| 清空回收站是否要二次确认？ | **是**，弹窗确认后才清空 |
| 时间显示格式？ | **具体日期** `2026-06-02 12:30` |
