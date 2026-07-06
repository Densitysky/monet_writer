import 'dart:io'; // 【核心新增】：引入 IO 库用于平台判断
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/pages/bookshelf/bookshelf_page.dart';
import 'package:monet_writer/pages/profile_page.dart';
import 'package:monet_writer/pages/desktop/desktop_home_page.dart';
import 'package:monet_writer/pages/splash_page.dart';
import 'package:monet_writer/pages/mobile/inspirations_page.dart';
import 'package:monet_writer/providers/inspirations_provider.dart';

void main() async {
  // 1. 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 【核心修复】：增加平台隔离，只有桌面端才初始化窗口管理器
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }

  // 2. 初始化中文日期格式数据
  await initializeDateFormatting('zh_CN', null);

  // 3. 初始化数据库服务
  await DatabaseService().init();

  // 4. 初始化用户数据 (预加载头像、昵称、设置)
  final userProvider = UserProvider();
  await userProvider.loadUserData();

  // 5. 初始化 AI 配置 (预加载 API Key)
  final aiProvider = AiProvider();
  await aiProvider.loadConfig();

  // 【核心修复】：仅在桌面端设定窗口参数和优雅现身逻辑
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 700),
      center: true,
      title: 'Monet Writer',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    // 6. 注入全局 Provider
    MultiProvider(
      providers: [
        // 主题管理
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 用户数据管理
        ChangeNotifierProvider.value(value: userProvider),
        // AI 配置管理
        ChangeNotifierProvider.value(value: aiProvider),
        // 灵感碎片管理
        ChangeNotifierProvider(create: (_) => InspirationsProvider()),
      ],
      child: const MonetApp(),
    ),
  );
}

class MonetApp extends StatelessWidget {
  const MonetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Monet Writer',
      debugShowCheckedModeBanner: false,

      // 对接 ThemeProvider 动态生成的的主题引擎
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,

      // 跟随系统或用户设置的主题模式
      themeMode: themeProvider.themeMode,

      // 启动页 -> 多端自适应主页
      home: SplashPage(
        nextPage: LayoutBuilder(
          builder: (context, constraints) {
            // 当屏幕/窗口宽度大于 800px 时，渲染桌面端骨架
            if (constraints.maxWidth > 800) {
              return const DesktopHomePage();
            }
            // 当宽度小于 800px (如手机或桌面小窗口)，渲染手机端底部导航脚手架
            return const MainScaffold();
          },
        ),
      ),
    );
  }
}

/// 手机端主脚手架：负责底部导航切换
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const BookshelfPage(),  // 索引 0: 写作/书架
    const InspirationsPage(), // 索引 1: 灵感碎片
    const ProfilePage(),    // 索引 2: 我的/设置
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App 进入后台时，让所有 Provider 有机会持久化
      context.read<ThemeProvider>().notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;

    // 柔和模式：三个独立悬浮图标按钮
    Widget bottomBar;
    if (isNeumorphic) {
      bottomBar = Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            _buildneumorphicNavItem(
              icon: Icons.book_outlined,
              selectedIcon: Icons.book,
              label: '写作',
              selected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            const SizedBox(width: 12),
            _buildneumorphicNavItem(
              icon: Icons.lightbulb_outline,
              selectedIcon: Icons.lightbulb,
              label: '灵感',
              selected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 12),
            _buildneumorphicNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: '我的',
              selected: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
      );
    } else {
      final navBar = NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '写作',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: '灵感',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      );

      bottomBar = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ),
          navBar,
        ],
      );
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: bottomBar,
    );
  }

  Widget _buildneumorphicNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F7FA) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    // 选中项：明显浮雕凸起
                    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
                    BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(4, 4), blurRadius: 16),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected
                    ? primary
                    : onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? primary
                      : onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}