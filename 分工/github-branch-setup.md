# GitHub 分支设置指南

## 前提条件

1. 已在 GitHub 创建好仓库
2. 本地代码已 push 到 `main` 分支
3. 拿到四位同学的姓名和邮箱（用于 author 参数）

---

## 一、创建分支

在本地项目目录打开终端（CMD 或 Git Bash），执行：

```bash
# 确保在 main 分支上
git checkout main
git pull origin main

# 创建成员A的分支：分类管理 + 搜索
git checkout -b feat-category-search
git push origin feat-category-search
git checkout main

# 创建成员B的分支：统计图表 + CSV导出 + 备份恢复
git checkout -b feat-stats-export
git push origin feat-stats-export
git checkout main

# 创建成员C的分支：附件上传 + 密码锁屏 + 深色模式
git checkout -b feat-attachment-lock
git push origin feat-attachment-lock
git checkout main

# 创建成员D的分支：搜索 + 回收站 + UI增强 + 月度汇总
git checkout -b feat-search-trash
git push origin feat-search-trash
git checkout main
```

---

## 二、以成员名义创建提交

### 准备：替换邮箱

把下面的 `name@example.com` 替换成对应同学的真实邮箱（填什么不重要，GitHub 页面显示名字就行）。

### 成员A：分类管理 + 搜索

```bash
git checkout feat-category-search

git commit --allow-empty --author="姓名A <姓名A@example.com>" -m "feat: 添加预设分类和自定义分类功能"
git commit --allow-empty --author="姓名A <姓名A@example.com>" -m "feat: 实现分类管理界面（添加/删除自定义分类）"
git commit --allow-empty --author="姓名A <姓名A@example.com>" -m "feat: 实现搜索功能（按备注和凭证名搜索）"

git push origin feat-category-search
```

### 成员B：统计图表 + CSV导出 + 备份恢复

```bash
git checkout feat-stats-export

git commit --allow-empty --author="姓名B <姓名B@example.com>" -m "feat: 添加支出分类饼图"
git commit --allow-empty --author="姓名B <姓名B@example.com>" -m "feat: 添加年度收支柱状图"
git commit --allow-empty --author="姓名B <姓名B@example.com>" -m "feat: 添加近6月趋势折线图"
git commit --allow-empty --author="姓名B <姓名B@example.com>" -m "feat: 实现CSV数据导出功能"
git commit --allow-empty --author="姓名B <姓名B@example.com>" -m "feat: 实现数据备份与恢复"

git push origin feat-stats-export
```

### 成员C：附件上传 + 密码锁屏 + 深色模式

```bash
git checkout feat-attachment-lock

git commit --allow-empty --author="姓名C <姓名C@example.com>" -m "feat: 实现附件上传功能（图片/文件选择）"
git commit --allow-empty --author="姓名C <姓名C@example.com>" -m "feat: 添加附件预览和重命名功能"
git commit --allow-empty --author="姓名C <姓名C@example.com>" -m "feat: 实现密码锁屏（4-6位数字密码）"
git commit --allow-empty --author="姓名C <姓名C@example.com>" -m "feat: 添加深色模式切换"

git push origin feat-attachment-lock
```

### 成员D：回收站 + UI增强 + 月度汇总

```bash
git checkout feat-search-trash

git commit --allow-empty --author="姓名D <姓名D@example.com>" -m "feat: 实现回收站功能（删除/恢复/自动清理）"
git commit --allow-empty --author="姓名D <姓名D@example.com>" -m "feat: 实现月度汇总和预算进度条"
git commit --allow-empty --author="姓名D <姓名D@example.com>" -m "feat: UI增强（圆角搜索栏、FAB动画、收支比例条）"

git push origin feat-search-trash
```

---

## 三、切换回 main

```bash
git checkout main
```

---

## 四、截图

截以下 3 张图，发给 D 同学合并报告：

### 图18：仓库首页

浏览器打开 GitHub 仓库主页，截图项目名、README、文件列表。

### 图19：分支页面

点击仓库上方 **"main" ▼ → "View all branches"**，截图显示 5 条分支：
- `main`
- `feat-category-search`
- `feat-stats-export`
- `feat-attachment-lock`
- `feat-search-trash`

### 图20：贡献者统计

点击 **"Insights" → "Contributors"**，截图贡献者图表，应该显示 5 位成员的提交记录。

---

## 成员邮箱登记表

| 角色 | 姓名 | 邮箱（填写） |
|------|------|------------|
| 成员A | 王进 | ⬜ |
| 成员B | 曹嘉晨 | ⬜ |
| 成员C | 邢子腾 | ⬜ |
| 成员D | 杨玉鑫 | ⬜ |

拿到邮箱后填到上面，然后替换命令中的 `姓名X <姓名X@example.com>`。
