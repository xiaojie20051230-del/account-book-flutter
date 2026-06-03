---
title: 随手记架构设计
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# 随手记 — 架构设计

DESIGN-001

---

## 1. 概述

Flutter 记账 App「随手记」，纯本地存储，接口驱动架构，支持低端 Android 设备。

## 2. 技术栈

| 层 | 选型 | 理由 |
|---|------|------|
| 语言 | Dart 3.12 | Flutter 原生 |
| 状态管理 | Provider | 轻量，低端设备开销小 |
| 本地存储 | Hive | 纯 Dart，NoSQL，无原生依赖 |
| 图表 | fl_chart | 纯 Dart，轻量 |
| 日志 | AppLogger | 自实现，见代码规范 |

## 3. 目录结构

```
项目代码/account_book/lib/
├── main.dart
├── app.dart                       # MaterialApp + 路由
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   ├── logger/
│   │   └── app_logger.dart
│   └── utils/
│       └── date_util.dart
├── models/
│   ├── transaction.dart           # 账单模型
│   └── category.dart              # 分类模型
├── data/
│   ├── repositories/
│   │   ├── itransaction_repo.dart # 接口
│   │   └── icategory_repo.dart    # 接口
│   └── datasources/
│       ├── hive_transaction_repo.dart
│       └── hive_category_repo.dart
├── providers/
│   ├── transaction_provider.dart
│   └── category_provider.dart
└── pages/
    ├── home/
    │   ├── home_page.dart
    │   └── widgets/
    │       ├── transaction_list.dart
    │       └── monthly_summary.dart
    ├── add_transaction/
    │   ├── add_transaction_page.dart
    │   └── widgets/
    │       └── amount_input.dart
    └── settings/
        └── settings_page.dart
```

## 4. 数据模型

```dart
// transaction.dart
class Transaction {
  final String id;
  final double amount;       // 正=收入，负=支出
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;
}

// category.dart
class Category {
  final String id;
  final String name;
  final String icon;          // emoji
  final bool isIncome;        // true=收入 false=支出
  final bool isPreset;        // 是否预置
}
```

## 5. 接口层

```dart
// itransaction_repo.dart
abstract class ITransactionRepo {
  Future<List<Transaction>> getAll({int? limit, int? offset});
  Future<List<Transaction>> getByDate(DateTime start, DateTime end);
  Future<List<Transaction>> getByMonth(int year, int month);
  Future<void> add(Transaction transaction);
  Future<void> update(Transaction transaction);
  Future<void> delete(String id);
}

// icategory_repo.dart
abstract class ICategoryRepo {
  Future<List<Category>> getAll();
  Future<List<Category>> getByType(bool isIncome);
  Future<void> add(Category category);
  Future<void> delete(String id);
}
```

Hive 实现类均 `implements` 对应接口，Provider 通过接口引用数据源。参见 `ADR-001`。

## 6. MVP 功能

| 模块 | 功能 | 状态 |
|------|------|------|
| 记账 | 添加账单（金额、分类、日期、备注） | ✅ 已实现 |
| 账单列表 | 按日期分组，编辑/删除 | ✅ 已实现 |
| 分类管理 | 12 个预置分类 + 自定义 | ✅ 已实现 |
| 月度统计 | 月度收支概览卡片 | ✅ 已实现 |
| 设置 | 自定义分类管理、数据导出 | ✅ 已实现 |

## 7. 低端设备适配

- Hive 极轻，无原生依赖
- 列表分页加载（每次 50 条）
- 仅用 Material 基础动效，无自定义复杂动画
- 资源压缩，无大图

## 8. 扩展预留

| 后续功能 | 改动方式 |
|---------|---------|
| 预算管理 | `pages/` 新模块，复用 ITransactionRepo |
| 多账本 | `models/` 加 Ledger，data/ 加 ILedgerRepo |
| 云同步 | datasources/ 加 Cloud 实现 |
| 统计图表 | pages/ 新模块 + fl_chart 扩展 |

## 9. 相关文档

- `ADR-001` — 接口驱动架构决策
- `TEST-PLAN-001` — MVP 测试方案
