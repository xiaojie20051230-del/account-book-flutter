---
title: Code Quality Improvements
status: Accepted
author: 吕加年
date: 2026-06-03
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# Code Quality Improvements

DESIGN-008

---

## 1. 需求

### 1.1 动机

代码审查（参见 REVIEW-001）发现多处可改进的问题，包括数据同步风险、性能瓶颈、交互不一致和代码健壮性。本文档定义这些问题的修复方案。

### 1.2 范围

仅涉及代码质量修复，不新增功能。所有修改保持现有行为不变。

### 1.3 修复清单

| 编号 | 问题 | 文件 | 严重程度 | 影响 |
|------|------|------|---------|------|
| FIX-01 | `Dismissible.onDismissed` 导致数据不同步 | `lib/pages/home/widgets/transaction_list.dart` | HIGH | 滑动删除后 widget 先移除，Provider 状态未及时刷新，可能引发 State 异常 |
| FIX-02 | 统计页多次 `where`/`fold` 遍历 + `_maxAmount` 12 月循环 | `lib/pages/stats/stats_page.dart` | MEDIUM | 数据量大时构建掉帧 |
| FIX-03 | 设置密码无二次确认 | `lib/pages/settings/settings_page.dart` | MEDIUM | 用户可能误触覆盖已有密码 |
| FIX-04 | `_RatioBar` 小比例时 `flex` 为 0 不渲染 | `lib/pages/home/widgets/transaction_list.dart` | LOW | 极低比例日期的比例条不可见 |
| FIX-05 | 饼图图例缺少分类名称 | `lib/pages/stats/stats_page.dart` | LOW | 图例仅有金额无法对应分类 |
| FIX-06 | `InteractiveViewer` 缩放无限 | `lib/pages/add_transaction/widgets/attachment_section.dart` | LOW | 图片可缩放到模糊 |
| FIX-07 | 长按删除与滑动删除逻辑重叠 | `lib/pages/home/widgets/transaction_list.dart` | LOW | 两种删除路径，用户困惑 |
| FIX-08 | `app.dart` 锁定逻辑状态残留 | `lib/app.dart` | LOW | `_showLock` 在无密码时仍被设置为 true |

---

## 2. 修改方案

### 2.1 FIX-01：Dismissible 改用 confirmDismiss

**文件：** `lib/pages/home/widgets/transaction_list.dart:146-172`

**当前代码：**
```dart
Dismissible(
  onDismissed: (_) {
    provider.moveToTrash(transaction);
    // widget 已从树移除
  },
)
```

**问题：** `Dismissible` 完成动画后立即从 widget 树移除子节点，但 `moveToTrash` 是异步操作（写 Hive + 更新 Provider），Provider 的 `notifyListeners()` 触发重建时 Dismissible 已被卸载，可能抛出 `StateError`。

**修改后：**
```dart
Dismissible(
  confirmDismiss: (_) async {
    provider.moveToTrash(transaction);
    return true; // 允许滑动完成
  },
)
```

同时移除 `_confirmDelete` 中的重复 SnackBar 逻辑，统一由 `moveToTrash` 内部或调用方管理 SnackBar 显示。

### 2.2 FIX-02：统计页计算性能优化

**文件：** `lib/pages/stats/stats_page.dart:26-55`

**当前模式：** 每次 `build` 时：
- `_StatsPage.build` 对全部 transactions 做一次 `where` 筛选
- `_MonthlyBarChart.build` 调用 `_maxAmount` getter 遍历 12 个月，每月又做 `where` + `fold`
- 合计每次构建：13 次全量遍历

**修改方案：** 在 `_StatsPageState` 中缓存按月分组的 Map，仅在 `transactions` 引用变化时重建：

```dart
class _StatsPageState extends State<StatsPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, List<Transaction>>? _cachedMonthData;

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    _cachedMonthData = null; // 每日志 rebuild 时重置缓存，确保数据最新
    // ...
  }

  List<Transaction> _getMonthData(List<Transaction> all, int y, int m) {
    // 简单缓存：相同 transactions 实例时复用
    return all.where((t) => t.date.year == y && t.date.month == m).toList();
  }
}
```

**`_maxAmount` 替代方案：** 改为在 BarChart 的 `build` 中单次遍历 12 个月，同时计算 `maxY` 和 `barGroups`：

```dart
// 一次性计算
final monthTotals = List.generate(12, (i) {
  final month = i + 1;
  final monthData = transactions.where((t) => ...).toList();
  return monthData.fold(0.0, ...);
});
final maxY = monthTotals.reduce((a, b) => a > b ? a : b) * 1.2;
```

### 2.3 FIX-03：设置密码增加二次确认

**文件：** `lib/pages/settings/settings_page.dart:162-215`

**当前流程：** 输入密码 → `setPasscode` → 完成

**修改后流程：** 输入密码 → 确认密码 → 匹配后 `setPasscode`

```dart
void _showPasscodeDialog(BuildContext context, {required bool isRemove}) {
  final ctrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  // 非移除模式时显示两个输入框
  if (!isRemove) {
    // 添加确认密码 TextField
    // 提交时校验两次输入一致
  }
}
```

### 2.4 FIX-04：RatioBar flex 最小值保障

**文件：** `lib/pages/home/widgets/transaction_list.dart:94-123`

**当前代码：**
```dart
Flexible(flex: (expenseRatio * 100).toInt(), ...)
```

**问题：** `expenseRatio * 100` 如为 0.01 ~ 0.99，`toInt()` 得 0，比例条消失。

**修改后：** 确保最小 flex 为 1（当比例 > 0 时）：

```dart
final expenseFlex = expense > 0 ? ((expenseRatio * 100).toInt()).clamp(1, 100) : 0;
final incomeFlex = income > 0 ? ((incomeRatio * 100).toInt()).clamp(1, 100) : 0;
```

### 2.5 FIX-05：饼图图例增加分类名称

**文件：** `lib/pages/stats/stats_page.dart:101-115`

**当前图例：** 仅显示金额数字

**修改后：** 传入 `CategoryProvider` 获取分类名称，图例显示格式为 `分类名 金额`：

```dart
// 图例条目
Row(
  children: [
    Container(width: 12, height: 12, decoration: ...),
    const SizedBox(width: 4),
    Text('$categoryName ¥${amount.toStringAsFixed(1)}', ...),
  ],
)
```

### 2.6 FIX-06：InteractiveViewer 缩放范围限制

**文件：** `lib/pages/add_transaction/widgets/attachment_section.dart:144-153`

```dart
InteractiveViewer(
  minScale: 0.5,
  maxScale: 4.0,
  child: Image.file(File(attachment.filepath)),
)
```

### 2.7 FIX-07：删除操作简化

**文件：** `lib/pages/home/widgets/transaction_list.dart:210-238`

**方案：** 移除 `_confirmDelete` 方法，仅保留滑动删除作为唯一删除入口。长按操作改为其他功能（如查看详情），或删除长按触发。

若保留长按删除作为可及性替代方案，统一使用 `confirmDismiss` 相同的确认文案和 SnackBar 行为。

### 2.8 FIX-08：锁定逻辑状态清理

**文件：** `lib/app.dart:61-66`

```dart
// 修改前
if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
  context.read<PasscodeProvider>().lock();
  setState(() => _showLock = true);
}

// 修改后
if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
  final passcode = context.read<PasscodeProvider>();
  if (passcode.shouldLock) {
    passcode.lock();
    setState(() => _showLock = true);
  }
}
```

---

## 3. 文件修改清单

| 文件 | 修改项 |
|------|--------|
| `lib/pages/home/widgets/transaction_list.dart` | FIX-01（Dismissible → confirmDismiss）、FIX-04（RatioBar flex）、FIX-07（删除逻辑简化） |
| `lib/pages/stats/stats_page.dart` | FIX-02（计算缓存）、FIX-05（图例改进） |
| `lib/pages/settings/settings_page.dart` | FIX-03（密码二次确认） |
| `lib/pages/add_transaction/widgets/attachment_section.dart` | FIX-06（缩放范围限制） |
| `lib/app.dart` | FIX-08（锁定逻辑条件） |

---

## 4. 验收标准

| # | 场景 | 预期 |
|---|------|------|
| 1 | 滑动删除账单 | 列表项正常移除，SnackBar 显示撤销选项，无 State 异常 |
| 2 | 统计页切换月份 | 图表流畅，无掉帧 |
| 3 | 设置密码时输入不一致 | 提示密码不匹配，拒绝保存 |
| 4 | 单日仅有极小收入或支出 | 比例条至少显示 1px |
| 5 | 饼图分类图例 | 显示分类名称 + 金额 |
| 6 | 图片预览放大到极限 | 不能缩放到超过 4x 或小于 0.5x |
| 7 | 未设置密码时切后台 | 不显示锁屏页，无状态残留 |

---

## 5. 开放问题

| 问题 | 决定 |
|------|------|
| 长按删除是否完全移除？ | 是，统一为滑动删除，去除 `_confirmDelete` |
| 统计页缓存是否需要失效机制？ | 每次 `build` 时重置，依赖 Flutter 框架的按需重建 |
| 密码确认 UI 采用两步对话框还是单步双输入框？ | 单步双输入框（一个对话框两个 TextField） |
