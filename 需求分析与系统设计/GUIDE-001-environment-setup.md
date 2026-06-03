---
title: 环境搭建
status: Accepted
author: 吕加年
date: 2026-05-26
version: 1.0
---

# Flutter 期末综合项目 — 环境搭建

## 一、开发环境概览

| 项目 | 说明 |
|------|------|
| **操作系统** | Windows 11 (25H2, 版本 10.0.26200) |
| **Flutter 版本** | 3.44.0 (stable channel) |
| **Dart 版本** | 3.12.0 |
| **Android SDK** | 36.0.0 |
| **开发工具** | VS Code / Android Studio |
| **测试设备** | Android 模拟器 / Chrome 浏览器 |

## 二、Flutter SDK 安装

### 2.1 SDK 位置
```
E:\临时\创新实验\flutter\flutter-sdk\
```

### 2.2 环境变量配置（已配置）

| 变量 | 值 |
|------|-----|
| `GIT_HOME` | `C:\Program Files\Git\cmd` |
| `ANDROID_HOME` | 已配置（SDK 36.0.0） |
| Flutter SDK bin | 已添加至系统 PATH |

## 三、Flutter doctor 检查结果

```
[√] Flutter (Channel stable, 3.44.0)
[√] Windows Version (Windows 11 or higher, 25H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK 36.0.0)
[√] Chrome - develop for the web
[!] Visual Studio - develop Windows apps (不完整，不影响 Android 开发)
[√] Connected device (3 available)
[√] Network resources
```

**说明：** Visual Studio 提示不完整仅影响 Windows 桌面应用开发，本项目为 Android 手机应用，无影响。

## 四、Android 模拟器

### 4.1 创建模拟器（如尚未创建）
```bash
flutter.bat emulators --create --name pixel_8 --device pixel_8
```

### 4.2 启动模拟器
```bash
# 列出可用模拟器
flutter.bat emulators

# 启动模拟器
flutter.bat emulators --launch pixel_8
```

### 4.3 查看已连接设备
```bash
flutter.bat devices
```

## 五、创建新项目

```bash
cd E:\临时\创新实验\flutter\02-期末综合项目
flutter.bat create project_name
```

## 六、Android Studio（推荐编辑器）

- 已安装 Flutter 和 Dart 插件
- 支持代码补全、热重载、调试
- 内置 Android 模拟器管理器

## 七、运行项目

```bash
cd E:\临时\创新实验\flutter\02-期末综合项目\项目代码
flutter.bat run
```

或连接设备后：

```bash
flutter.bat run -d <device_id>
```
