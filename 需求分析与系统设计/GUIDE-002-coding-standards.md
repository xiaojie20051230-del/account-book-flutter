---
title: 代码规范
status: Accepted
author: 吕加年
date: 2026-05-26
version: 1.0
---

# Flutter 期末综合项目 — 代码规范

## 一、项目目录结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # MaterialApp 配置
├── core/                     # 核心基础设施
│   ├── constants/            # 常量定义
│   │   └── app_constants.dart
│   ├── theme/                # 主题配置
│   │   └── app_theme.dart
│   ├── utils/                # 工具类
│   │   └── date_util.dart
│   └── logger/               # 日志系统（重点）
│       └── app_logger.dart
├── models/                   # 数据模型
│   └── user.dart
├── services/                 # 业务服务层
│   └── data_service.dart
├── providers/                # 状态管理（ChangeNotifier / Riverpod / Bloc）
│   └── app_provider.dart
├── pages/                    # 页面（按功能模块划分）
│   ├── home/
│   │   ├── home_page.dart
│   │   └── widgets/
│   │       └── home_header.dart
│   └── settings/
│       ├── settings_page.dart
│       └── widgets/
├── widgets/                  # 全局复用组件
│   └── common_button.dart
└── routes.dart               # 路由配置
```

## 二、日志规范（强制要求）

### 2.1 日志级别

| 级别 | 使用场景 | 输出颜色 |
|------|----------|----------|
| `verbose` | 详细流程跟踪，进入/退出函数 | 灰色 |
| `debug` | 调试信息，变量值打印 | 蓝色 |
| `info` | 重要业务流程节点 | 绿色 |
| `warning` | 非致命异常，可恢复错误 | 黄色 |
| `error` | 致命错误，功能异常 | 红色 |

### 2.2 日志输出规则

1. **每个函数入口必须打印日志**
   ```dart
   void fetchUserData(String userId) {
     AppLogger.info('开始获取用户数据', tag: 'UserService', data: {'userId': userId});
     // ...
   }
   ```

2. **每个函数出口必须打印日志（正常/异常分支都要）**
   ```dart
   void fetchUserData(String userId) {
     AppLogger.info('开始获取用户数据', tag: 'UserService');
     try {
       final data = api.getUser(userId);
       AppLogger.info('获取用户数据成功', tag: 'UserService', data: {'name': data.name});
     } catch (e, stackTrace) {
       AppLogger.error('获取用户数据失败', tag: 'UserService', error: e, stackTrace: stackTrace);
     }
   }
   ```

3. **异步操作必须记录开始、完成、失败三种状态**
   ```dart
   Future<void> loadData() async {
     AppLogger.info('异步加载开始', tag: 'HomePage');
     try {
       final result = await api.fetch();
       AppLogger.info('异步加载完成', tag: 'HomePage', data: {'count': result.length});
     } catch (e, stackTrace) {
       AppLogger.error('异步加载失败', tag: 'HomePage', error: e, stackTrace: stackTrace);
     }
   }
   ```

4. **用户操作必须记录**
   ```dart
   void onSubmitPressed() {
     AppLogger.info('用户点击提交按钮', tag: 'UI');
   }
   ```

### 2.3 日志格式

```
[2024-01-15 09:32:15.234] [INFO] [UserService] 获取用户数据成功
    ├── 文件: lib/services/user_service.dart:42
    ├── 数据: {userId: "12345", name: "张三"}
    └── 耗时: 234ms
```

### 2.4 日志实现类

```dart
// lib/core/logger/app_logger.dart

import 'dart:developer' as developer;

enum LogLevel { verbose, debug, info, warning, error }

class AppLogger {
  static LogLevel _minLevel = LogLevel.verbose;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void v(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.verbose, message, tag: tag, data: data);
  }

  static void d(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  static void i(String message, {String tag = 'APP', Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  static void w(String message, {String tag = 'APP', Map<String, dynamic>? data, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, data: data, error: error);
  }

  static void e(String message, {
    String tag = 'APP',
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final time = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln('[$time] [$levelStr] [$tag] $message');
    if (data != null) buffer.writeln('    DATA: $data');
    if (error != null) buffer.writeln('    ERROR: $error');
    if (stackTrace != null) buffer.writeln('    STACK: $stackTrace');

    developer.log(
      buffer.toString(),
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
```

## 三、命名规范

### 3.1 文件命名
- Dart 文件：`snake_case.dart`（如 `user_service.dart`）
- 页面文件：`xxx_page.dart`
- 组件文件：`xxx_widget.dart`

### 3.2 类命名
- 类名：`PascalCase`（如 `UserService`）
- 页面类：`PascalCase + Page`（如 `HomePage`）
- Widget 类：`PascalCase + Widget`（如 `CustomButton`）

### 3.3 变量与函数命名
- 变量：`camelCase`（如 `userName`）
- 常量：`k + PascalCase`（如 `kDefaultTimeout`）
- 布尔变量：使用 `is`、`has`、`should` 前缀（如 `isLoading`）
- 函数：`camelCase`，动词开头（如 `fetchUserData`）
- 私有成员：下划线前缀（如 `_internalData`）

## 四、错误处理规范

1. **所有异步操作必须 try-catch**
   ```dart
   Future<void> loadData() async {
     try {
       final data = await api.fetch();
     } on NetworkException catch (e) {
       AppLogger.w('网络异常', tag: 'API', error: e);
       // 处理网络错误
     } catch (e, stackTrace) {
       AppLogger.e('未知异常', tag: 'API', error: e, stackTrace: stackTrace);
       // 处理其他错误
     }
   }
   ```

2. **使用 Result 类型或异常传递错误**
   ```dart
   Future<Result<User, AppError>> getUser(String id) async {
     try {
       final user = await _fetch(id);
       return Result.success(user);
     } catch (e) {
       return Result.failure(AppError.from(e));
     }
   }
   ```

3. **UI 层必须处理错误状态**
   ```dart
   if (state.isError) {
     return ErrorWidget(message: state.errorMessage);
   }
   ```

## 五、状态管理规范

1. **使用 ChangeNotifier / Riverpod / Bloc 之一，不要混用**
2. **状态类使用不可变对象**
   ```dart
   @immutable
   class HomeState {
     final bool isLoading;
     final List<Item> items;
     final String? errorMessage;

     const HomeState({
       this.isLoading = false,
       this.items = const [],
       this.errorMessage,
     });

     HomeState copyWith({bool? isLoading, List<Item>? items, String? errorMessage}) {
       return HomeState(
         isLoading: isLoading ?? this.isLoading,
         items: items ?? this.items,
         errorMessage: errorMessage ?? this.errorMessage,
       );
     }
   }
   ```

3. **状态变更必须记录日志**
   ```dart
   void loadItems() async {
     AppLogger.i('开始加载列表', tag: 'HomeProvider');
     _state = _state.copyWith(isLoading: true);
     notifyListeners();

     try {
       final items = await service.fetchItems();
       _state = _state.copyWith(isLoading: false, items: items);
       AppLogger.i('列表加载成功', tag: 'HomeProvider', data: {'count': items.length});
     } catch (e, stackTrace) {
       _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
       AppLogger.e('列表加载失败', tag: 'HomeProvider', error: e, stackTrace: stackTrace);
     }
     notifyListeners();
   }
   ```

## 六、注释规范

1. **类注释**
   ```dart
   /// 用户数据服务类
   /// 负责用户相关的网络请求和数据缓存
   class UserService {
   ```

2. **函数注释**
   ```dart
   /// 根据用户ID获取用户信息
   /// [userId] 用户唯一标识
   /// 返回 [User] 对象，若不存在则返回 null
   Future<User?> getUserById(String userId) async {
   ```

3. **复杂逻辑注释**
   ```dart
   // 使用防抖避免频繁请求，等待 500ms 后执行
   _debounceTimer?.cancel();
   _debounceTimer = Timer(Duration(milliseconds: 500), () {
     _performSearch(query);
   });
   ```

## 七、代码审查清单

提交前自检：
- [ ] 所有函数入口有日志
- [ ] 所有异常分支有日志
- [ ] 所有用户操作有日志
- [ ] 异步操作记录开始/完成/失败
- [ ] 无 `print()` 语句，全部使用 `AppLogger`
- [ ] 错误处理完整，无裸 `catch`
- [ ] 状态类不可变
- [ ] 命名符合规范
- [ ] 函数不超过 50 行
- [ ] 文件不超过 400 行
