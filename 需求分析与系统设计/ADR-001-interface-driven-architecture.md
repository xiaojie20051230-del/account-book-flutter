---
title: 接口驱动架构决策
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
revision_history:
  - 1.0 — 初始版本
---

# 接口驱动架构决策

ADR-001

---

## 1. 上下文

随手记 MVP 只需要纯本地存储（Hive），后续可能扩展功能（预算管理、多账本、云同步）。需要一种架构：

- MVP 阶段代码量最小
- 后续扩展时不改现有代码
- 适合 Flutter/Dart 语言特性

## 2. 可选方案

### 方案 A：直接实现（无接口）

```
class TransactionService {
  final Box _box;  // 直接操作 Hive
}
```

- **优点**：代码最少，MVP 最快
- **缺点**：换存储或加数据源要改实现类

### 方案 B：接口驱动 + Repository 模式（已选）

```
abstract class ITransactionRepo {}
class HiveTransactionRepo implements ITransactionRepo {}
```

- **优点**：扩展加实现类即可，不改现有代码
- **缺点**：多一层文件，MVP 阶段多几行代码

### 方案 C：Clean Architecture（Domain/Data/Presentation）

- **优点**：架构最清晰
- **缺点**：过度设计，MVP 体量不需要 UseCase 层

## 3. 决策

选择**方案 B：接口驱动 + Repository 模式**。

理由：
1. Dart 原生支持 `abstract class` + `implements`，零额外成本
2. 后续加云同步只需 `CloudTransactionRepo implements ITransactionRepo`
3. Provider 通过接口引用数据源，换实现不改 Provider 代码
4. 比 Clean Architecture 轻量，不引入 UseCase 层

## 4. 影响

**变容易了：**
- 添加新数据源（云同步、SQLite）只需新写实现类
- 单元测试可以 mock 接口

**变难了：**
- 每个数据模块多一个接口文件
- 纯本地场景下接口是多余的抽象层

## 5. 相关文档

- `DESIGN-001` §5 — 接口定义详情
- `TEST-PLAN-001` — 测试方案中仓储测试覆盖接口实现
