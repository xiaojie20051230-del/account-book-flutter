---
title: UI Enhancement
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# UI Enhancement

DESIGN-006

---

## 1. Requirements

### 1.1 Motivation

参考 FinTrack 项目的 UI 设计，对手随手记的部分界面进行视觉和交互优化。

### 1.2 Goals

| Requirement | Priority |
|-------------|----------|
| 首页搜索栏改为圆角样式 | P0 |
| 账单列表增加筛选按钮（日期/分类/类型） | P0 |
| 统计页面增加趋势折线图 | P1 |
| 日期分组增加收支比例条 | P1 |
| FAB 滚动时收起动画 | P2 |

### 1.3 Non-goals

- 不改变整体布局结构（底部导航、页面划分保持不变）
- 不引入新的页面
- 不涉及后端逻辑变更

---

## 2. UI Changes

### 2.1 Search Bar

**Before:** Inline TextField with border  
**After:** Tappable rounded container with search icon

```dart
// Current: full TextField
TextField(
  onChanged: (v) => provider.search(v),
  decoration: InputDecoration(
    hintText: '搜索备注...',
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
)

// New: styled search bar that navigates to search
GestureDetector(
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => const SearchPage(),
  )),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(children: [
      Icon(Icons.search, color: Colors.grey[600]),
      const SizedBox(width: 8),
      Text('搜索交易', style: TextStyle(color: Colors.grey[600])),
    ]),
  ),
)
```

### 2.2 Filter Buttons

Add filter chips above transaction list in the "全部账单" view:

```
[日期 ▼]  [分类 ▼]  [类型 ▼]     ← OutlinedButton, selected state highlighted
```

Each button opens a bottom sheet / dialog for selection.

### 2.3 Trend Line Chart

Add a new chart type to statistics page:

```dart
// Line chart showing income/expense over selected period
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(yValues: monthlyExpenses, color: Colors.red),
      LineChartBarData(yValues: monthlyIncomes, color: Colors.green),
    ],
  ),
)
```

Tab switching: 月 / 周 / 年 / 自定义

### 2.4 Date Group Ratio Bar

Small vertical bar next to each date group header:

```
█ 06-02 周二                支 29.90
  ↑ green = income ratio
  ↓ red = expense ratio
```

### 2.5 FAB Scroll Behavior

```dart
// Auto-hide extended label on scroll
if (_scrollController.offset > 50) {
  setState(() => _isFabExtended = false);
} else {
  setState(() => _isFabExtended = true);
}
```

---

## 3. Files

| File | Change |
|------|--------|
| `lib/pages/home/home_page.dart` | Modify: search bar style, FAB scroll behavior |
| `lib/pages/home/widgets/transaction_list.dart` | Modify: date group ratio bar |
| `lib/pages/stats/stats_page.dart` | Modify: add line chart, tab switching |
| `lib/pages/home/widgets/filter_bar.dart` | NEW: filter buttons component |
| `lib/pages/home/search_page.dart` | NEW: dedicated search page (tappable bar navigates here) |

---

## 4. Acceptance Criteria

| # | Scenario | Expected |
|---|----------|---------|
| 1 | Home page search bar | Rounded style, tappable, navigates to search page |
| 2 | Filter buttons | Date/category/type, selected state highlighted |
| 3 | Trend line chart | Line chart displays, tab switching works |
| 4 | Ratio bar on date | Small vertical bar shows income/expense ratio |
| 5 | FAB scroll | Extended label hides on scroll down, shows on scroll up |

---

## 5. Open Questions

| Question | Decision |
|----------|----------|
| Filter state persistence? | In-memory only, reset on page reload |
| Line chart period options? | 月/周/年/自定义 |
