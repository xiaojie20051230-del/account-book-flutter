import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'pages/home/home_page.dart';
import 'pages/lock/lock_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/stats/stats_page.dart';
import 'providers/passcode_provider.dart';
import 'providers/theme_provider.dart';

class AccountBookApp extends StatelessWidget {
  const AccountBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: '随手记',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
      routes: {
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    StatsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // BUG-002: 有密码则立即锁屏
    final passcode = context.read<PasscodeProvider>();
    if (passcode.shouldLock) {
      passcode.lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // BUG-014: 补充 detached 状态
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final passcode = context.read<PasscodeProvider>();
      if (passcode.shouldLock) {
        passcode.lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final passcode = context.watch<PasscodeProvider>();

    // BUG-004: 统一使用 passcode.isLocked
    if (passcode.isLocked) {
      return LockPage(onUnlocked: () => passcode.unlock());
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '统计'),
        ],
      ),
    );
  }
}
