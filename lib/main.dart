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

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const BookshelfPage(),  // 索引 0: 写作/书架
    const InspirationsPage(), // 索引 1: 灵感碎片
    const ProfilePage(),    // 索引 2: 我的/设置
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 显示当前选中的页面
      body: _pages[_currentIndex],

      // 底部导航栏
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          ),
          NavigationBar(
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
          ),
        ],
      ),
    );
  }
}