# 任务 A：用 AI 生成功能草图和业务流程图

## 你的任务

用 AI 绘图工具生成 6 张功能草图和 1 张业务流程图，整理成 Word 文档。

**不用自己画，全部用 AI 生成。**

---

## 交付物

| 文件 | 说明 |
|------|------|
| `A-实验目的与草图.docx` | 包含实验目的、实验设备、项目概述、6张AI草图、1张AI流程图 |

---

## 第一步：选 AI 绘图工具

| 工具 | 网址 | 费用 |
|------|------|------|
| **通义万相**（推荐） | https://tongyi.aliyun.com/wanxiang | 免费 |
| **文心一格** | https://yige.baidu.com/ | 免费 |
| DALL-E 3 | ChatGPT Plus | 付费 |
| Midjourney | Discord | 付费 |

**推荐用通义万相或文心一格，免费而且国内直接用。**

---

## 第二步：用提示词生成 7 张图

把下面的提示词**逐条复制**到 AI 绘图工具中生成图片。每张图多生成几次选最好看的。

---

### 图1：首页

提示词：
```
A mobile app UI design for a personal finance tracking app called "随手记". The home screen shows: top bar with year/month title, a rounded search bar with search icon, a summary card showing balance amount in large font, a list of transaction items grouped by date, each showing category icon, name and amount, a floating blue "+" button at bottom right. Material Design style, clean white background, smartphone mockup.
```

### 图2：添加账单页

提示词：
```
A mobile app UI screen for adding a transaction in "随手记" app. The screen shows: top bar with title, two toggle buttons for expense and income, an amount input field with ¥ prefix, a date picker, grid of category chips with icons (food, transport, shopping, entertainment), a notes text field, a blue submit button. Material Design 3, clean modern interface, smartphone mockup.
```

### 图3：统计页

提示词：
```
A mobile app statistics screen for a finance app. Shows: a colorful pie chart with percentage labels, a bar chart with green and red bars for 12 months, a line chart showing 6-month trend. Clean white background, Material Design style, data visualization, smartphone mockup.
```

### 图4：设置页

提示词：
```
A mobile app settings screen for a Chinese finance app. Multiple sections: category management, data management with CSV export and backup, budget setting, dark mode toggle, passcode lock setting. Each section has icon and description. Material Design 3, clean list layout, smartphone mockup.
```

### 图5：搜索页

提示词：
```
A mobile app search screen for a finance app. Search bar at top with magnifying glass icon. Search results list showing transactions with category icon, name, time and amount. Amounts in red for expenses, green for income. Material Design style, white background, smartphone mockup.
```

### 图6：锁屏页

提示词：
```
A mobile app lock screen with passcode protection. Lock icon at top, title text "请输入密码", row of empty circles for PIN input, numeric keypad with digits 1-9 and 0, backspace button. Clean minimal design, smartphone lock screen mockup.
```

### 图7：业务流程图

提示词：
```
A business flow diagram for a mobile finance app. Flow starts from open app to home page, then branching to: add transaction, edit transaction, swipe to delete, search, view statistics, settings. Rectangular boxes with arrows connecting them. Clean professional flowchart style.
```

---

## 第三步：写文字内容

文档里还需要以下文字，**直接复制**：

### 实验目的

```
1. 能够以小组为单位开发手机/跨平台APP。
2. 能够完成项目功能草图、页面或屏幕设计、业务流程图和运行截图。
3. 能够基于代码托管平台进行协同开发，明确成员贡献。
```

### 实验设备

```
计算机（Windows 11）、Flutter 3.44 开发环境、Android Studio、Hive 本地数据库、Provider 状态管理、Git 代码托管平台、截图工具、WPS 文档编辑工具。
```

### 项目概述

```
本小组以 Flutter 框架开发了"随手记"跨平台记账 App。
采用 Provider 状态管理 + Hive 本地存储架构，
实现了账单管理、分类管理、月度统计、CSV 导出、回收站、密码锁屏等功能。
项目代码已上传至 GitHub。

前期完成了完整的设计文档（参见 DESIGN-001~008），
涵盖架构设计（接口驱动+Repository模式）、功能扩展、
回收站机制、附件系统、密码锁等功能规格说明。
```

---

## 第四步：整理 Word 文档

1. **字体宋体、5号、1.5倍行距**
2. 顺序：实验目的 → 实验设备 → 项目概述 → 图1~图7
3. 每张图下方写：`图X：页面名称`
4. 保存为 **`A-实验目的与草图.docx`**
5. 发到群里

---

## 用时估计

约 1-2 小时（主要是生成图片和挑图的时间）
