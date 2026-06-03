---
title: Code Review Findings Batch 2
status: Proposed
author: 吕加年
date: 2026-06-03
version: 1.1
revision_history:
  - 1.1 — 部分实现（BUG-018/019/021 代码已改）
  - 1.0 — 初始版本
---

# Code Review Findings Batch 2

BUGFIX-002

---

## 1. 需求

### 1.1 动机

代码审查（REVIEW-002）发现 10 项问题，覆盖安全漏洞、性能瓶颈、重复代码和稳定性。

### 1.2 修复清单

| 编号 | 问题 | 文件 | 严重度 | 状态 |
|------|------|------|--------|------|
| BUG-018 | CSV 注入：catName 未转义 + UTF-16 编码 | `lib/data/export/csv_exporter.dart` | 高 | ✅ v1.1 |
| BUG-019 | 备份路径遍历：restore 未校验文件名 | `lib/data/export/backup_manager.dart` | 高 | ✅ v1.1 |
| BUG-020 | 备份兼容性：旧格式读取可能中断 | `lib/data/export/backup_manager.dart` | 中 | ✅ v1.1 |
| BUG-021 | _pad 重复：多处重复定义 | `lib/core/utils/date_util.dart` | 低 | ✅ v1.1 |
| BUG-022 | 统计页性能：月份数据 3 次全量遍历 | `lib/pages/stats/stats_page.dart` | 中 | ❌ 待实现 |
| BUG-023 | 搜索防抖：每次输入都查附件 | `lib/pages/home/search_page.dart` | 低 | ❌ 待实现 |
| BUG-024 | 删除分类无确认 | `lib/pages/settings/settings_page.dart` | 低 | ❌ 待实现 |
| BUG-025 | 预算输入静默忽略 | `lib/pages/settings/settings_page.dart` | 低 | ❌ 待实现 |
| BUG-026 | 恢复失败无回滚 | `lib/data/export/backup_manager.dart` | 中 | ✅ v1.1 |
| BUG-027 | 权限检查可精简 | `lib/pages/add_transaction/widgets/attachment_section.dart` | 低 | ✅ v1.1 |

---

## 2. UI / 数据流

### 2.1 CSV 导出数据流（BUG-018）

```
Export → 逐行拼接 → _escapeCsv → 仅转义了 note → catName 直接拼接
                                          ↓
                                    `,` 或 `"` 破坏 CSV 列结构
```

修复：所有字段都过 `_escapeCsv`，`_writeTempFile` 用 `utf8.encode` 替代 `codeUnits`。

### 2.2 备份恢复数据流（BUG-019/020/026）

```
选择 .abk → 读取字节 → 解析文件名 → 拼接路径 → 写入
                                      ↓
                              name = "../../config" 可覆盖外部文件
```

修复：校验文件名仅允许 `[a-zA-Z0-9._-]`，写入前先写临时目录再覆盖。

### 2.3 统计页计算（BUG-022）

```
build → _MonthlyBarChart → 遍历 12 月 × 12 次 where + 12 次 fold
                        → _maxAmount 又遍历 12 次 where
     → _TrendLineChart → 遍历 6 月 × 6 次 where
                        = 42 次全量遍历 / 每次 build
```

修复：一次遍历按月分组，缓存结果。

---

## 3. 组件设计

### 3.1 文件修改清单

| 文件 | 修改项 |
|------|--------|
| `lib/data/export/csv_exporter.dart` | BUG-018: 字段全转义 + utf8.encode |
| `lib/data/export/backup_manager.dart` | BUG-019/020/026: 文件名校验 + 回滚 |
| `lib/core/utils/date_util.dart` | BUG-021: `_pad` 改为公开 `pad` |
| `lib/providers/attachment_provider.dart` | BUG-021: 复用 `DateUtil.pad` |
| `lib/pages/stats/stats_page.dart` | BUG-022: 一次遍历按月分组 |
| `lib/pages/home/search_page.dart` | BUG-023: 300ms 防抖 |
| `lib/pages/settings/settings_page.dart` | BUG-024/025: 删除确认 + 预算提示 |

### 3.2 变更详情

#### 3.2.1 CSV 导出 — 字段全转义 + UTF-8

```dart
// BUG-018: 所有字段转义 + UTF-8
String _buildCsv(List<Transaction> transactions) {
  final buffer = StringBuffer();
  buffer.writeln('日期,类型,分类,金额,备注');
  for (final t in transactions) {
    final catName = _categoryMap?[t.categoryId]?.name ?? t.categoryId;
    buffer.writeln('${_escapeCsv(DateUtil.formatDate(t.date))},'
        '${_escapeCsv(t.isIncome ? "收入" : "支出")},'
        '${_escapeCsv(catName)},'
        '${t.amount.toStringAsFixed(2)},'
        '${_escapeCsv(t.note)}');
  }
  return buffer.toString();
}

// _writeTempFile 用 utf8.encode
await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
```

#### 3.2.2 备份 — 文件名校验

```dart
// BUG-019: 只允许安全字符
final safeName = RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(name);
if (!safeName) continue;
```

#### 3.2.3 DateUtil — 公开 pad

```dart
// BUG-021: 改为公开
static String pad(int n) => n.toString().padLeft(2, '0');
```

---

## 4. 验收标准

| # | 场景 | 预期 |
|---|------|------|
| 1 | CSV 导出含 `,` 或 `"` 的分类名 | CSV 列结构完整，字段被引号包裹 |
| 2 | CSV 文件编码 | UTF-8 BOM，中文不乱码 |
| 3 | 恢复含恶意路径的备份 | 拒绝 `../` 等路径穿越 |
| 4 | 恢复过程中失败 | 不破坏原有数据 |
| 5 | 统计页图表渲染 | 流畅不卡顿 |
| 6 | 搜索输入快速打字 | 300ms 防抖后才发起查询 |
| 7 | 删除自定义分类 | 弹确认框 |
| 8 | 输入无效预算 | SnackBar 提示 |

---

## 5. 开放问题

| 问题 | 决定 |
|------|------|
| BUG-022: 缓存粒度？ | 每次 `transactions` 引用变化时重建 |
| BUG-023: 防抖时长？ | 300ms |
| BUG-026: 回滚策略？ | 先写临时目录，成功后替换 |
