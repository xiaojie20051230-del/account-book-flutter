---
title: 随手记功能扩展设计
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# 随手记 — 功能扩展设计

DESIGN-002

---

## 1. 概述

在 MVP 基础上扩展实用功能，优先级按用户价值排列。

---

## 2. 功能优先级

| 优先级 | 功能 | 工作量 | 依赖 | 说明 |
|--------|------|--------|------|------|
| **P0** | CSV 导出 + 分享 | 小 | — | 核心诉求，手机导出发到电脑 |
| **P1** | 统计图表 | 中 | fl_chart 已安装 | 饼图+柱状图看支出分布 |
| **P2** | 搜索筛选 | 中 | — | 按分类/日期/关键字搜索 |
| **P3** | 预算管理 | 中 | — | 每月设预算，超支提醒 |
| **P4** | 暗黑模式 | 小 | — | 深色主题切换 |
| **P5** | 指纹解锁 | 小 | local_auth | 隐私保护 |

---

## 3. P0 — CSV 导出 + 分享

### 3.1 功能描述

设置页「导出数据」不再显示"功能待开发"，改为：
1. 点击后生成 CSV 文件
2. 调用系统分享（微信/QQ/邮件等）
3. 用户选择目标应用发送到电脑

### 3.2 CSV 格式

```csv
日期,类型,分类,金额,备注
2026-06-02,支出,餐饮,29.9,午餐
2026-06-02,收入,工资,5000.0,工资
```

### 3.3 技术方案

- 新增依赖：`share_plus`（跨平台分享）
- 新增文件：`lib/data/export/csv_exporter.dart`
- 逻辑：从 `ITransactionRepo` 取数据 → 拼 CSV → 写入临时文件 → 调用系统分享

### 3.4 文件清单

| 文件 | 说明 |
|------|------|
| `lib/data/export/csv_exporter.dart` | CSV 生成 + 分享逻辑 |
| `lib/pages/settings/settings_page.dart` | 修改，接入导出功能 |

---

## 4. P1 — 统计图表

### 4.1 功能描述

新增统计页面，展示：
1. **饼图**：当月各分类支出占比
2. **柱状图**：近 6 个月收支趋势

### 4.2 技术方案

- 复用已安装的 `fl_chart` 包
- 新增页面：`lib/pages/stats/stats_page.dart`
- 底部导航栏增加「统计」入口

### 4.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/pages/stats/stats_page.dart` | 统计主页（饼图+柱状图） |
| `lib/pages/stats/widgets/category_pie_chart.dart` | 分类饼图组件 |
| `lib/pages/stats/widgets/monthly_bar_chart.dart` | 月度趋势柱状图 |
| `lib/pages/home/home_page.dart` | 修改，增加底部导航 |

---

## 5. P2 — 搜索筛选

### 5.1 功能描述

首页搜索栏，支持：
- 按分类筛选
- 按日期范围筛选
- 按关键字搜索备注

### 5.2 技术方案

- 在 `TransactionProvider` 增加筛选方法
- 首页顶部增加搜索栏/筛选条件

### 5.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/providers/transaction_provider.dart` | 增加筛选逻辑 |
| `lib/pages/home/widgets/search_bar.dart` | 搜索栏组件 |
| `lib/pages/home/widgets/filter_chips.dart` | 筛选条件组件 |

---

## 6. P3 — 预算管理

### 6.1 功能描述

每月设置总预算（或按分类设预算）：
- 设置页增加预算管理入口
- 月度汇总卡片上显示预算进度条
- 超预算时红字提醒

### 6.2 技术方案

- 新增 `Budget` 模型 + Hive 存储
- 复用 `ITransactionRepo` 计算当月已支出

### 6.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/models/budget.dart` | 预算模型 |
| `lib/data/repositories/ibudget_repo.dart` | 预算仓储接口 |
| `lib/data/datasources/hive_budget_repo.dart` | Hive 实现 |
| `lib/pages/settings/budget_page.dart` | 预算设置页 |
| `lib/pages/home/widgets/budget_progress.dart` | 预算进度条组件 |

---

## 7. P4 — 暗黑模式

### 7.1 功能描述

设置页增加主题切换（浅色/深色/跟随系统）。

### 7.2 技术方案

- 使用 `ThemeMode` 枚举
- 通过 Provider 全局管理主题状态
- 持久化选择到 SharedPreferences

### 7.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/providers/theme_provider.dart` | 主题状态管理 |
| `lib/pages/settings/settings_page.dart` | 增加主题切换选项 |

---

## 8. P5 — 指纹解锁

### 8.1 功能描述

App 启动时或从后台恢复时要求指纹/面部解锁。

### 8.2 技术方案

- 新增依赖：`local_auth`
- 设置页增加开关
- App 生命周期监听 + 解锁页面

### 8.3 文件清单

| 文件 | 说明 |
|------|------|
| `lib/pages/lock/lock_page.dart` | 解锁页面 |
| `lib/providers/auth_provider.dart` | 认证状态管理 |

---

## 9. 实施计划

```
Phase 1 (P0):  CSV 导出 + 分享       → 1 次提交
Phase 2 (P1):  统计图表               → 2 次提交（饼图 + 柱状图）
Phase 3 (P2):  搜索筛选               → 1 次提交
Phase 4 (P3):  预算管理               → 2 次提交（模型 + UI）
Phase 5 (P4):  暗黑模式               → 1 次提交
Phase 6 (P5):  指纹解锁               → 1 次提交
```

---

## 10. 相关文档

- `DESIGN-001` — 随手记架构设计（原始架构）
- `TEST-PLAN-001` — MVP 测试方案
