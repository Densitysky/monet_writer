import 'package:flutter/material.dart';
// 【新增】：引入基础库，用于判断当前运行的操作系统平台
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义应用的主题风格
enum AppThemeStyle {
  modern, // 当前的 Material 3 拟物/微浮雕风
  flat,   // 全新的极简扁平风 (桌面/移动端同享顶级质感)
}

/// 主题状态管理
class ThemeProvider extends ChangeNotifier {
  Color _seedColor = const Color(0xFF3A7CA5); // 天湖蓝 — 金律主色
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _themeStyle = AppThemeStyle.modern;

  /// 金律色盘 — 24色，黄金角度 137.5° 分布
  static const List<Color> goldenAngleColors = [
    // 金律原色
    Color(0xFFE8618C), Color(0xFFE8853A), Color(0xFFD4A017),
    Color(0xFF2E8B57), Color(0xFF3A7CA5), Color(0xFF7B5EA7),
    // 莫奈自然色
    Color(0xFFE2B2B1), Color(0xFFC9A96E), Color(0xFF8B9A6E),
    Color(0xFFA0B4C8), Color(0xFF9A8FBF), Color(0xFFB0ADA6),
    // 深沉色
    Color(0xFF9B2D3C), Color(0xFF8B5E34), Color(0xFF1A6B54),
    Color(0xFF1B4F72), Color(0xFF4A3572), Color(0xFF3D3D3D),
    // 无色系
    Color(0xFFFAFAF8), Color(0xFFF0EFEA), Color(0xFFE2E1DD),
    Color(0xFFB0AEAA), Color(0xFF5C5B57), Color(0xFF1C1C1A),
  ];

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get themeStyle => _themeStyle;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final colorValue = prefs.getInt('theme_seed_color');
      if (colorValue != null) _seedColor = Color(colorValue);

      final modeIndex = prefs.getInt('theme_mode');
      if (modeIndex != null) _themeMode = ThemeMode.values[modeIndex];

      final styleIndex = prefs.getInt('theme_style');
      if (styleIndex != null) _themeStyle = AppThemeStyle.values[styleIndex];

      notifyListeners();
    } catch (e) {
      debugPrint("加载主题设置失败: $e");
    }
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_seed_color', color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_style', style.index);
  }

  ThemeData get lightTheme => _themeStyle == AppThemeStyle.flat
      ? _buildFlatTheme(Brightness.light)
      : _buildModernTheme(Brightness.light);

  ThemeData get darkTheme => _themeStyle == AppThemeStyle.flat
      ? _buildFlatTheme(Brightness.dark)
      : _buildModernTheme(Brightness.dark);

  // ==========================================
  // 【桌面端专属】全局 macOS 级优雅滚动条样式
  // ==========================================
  ScrollbarThemeData? _buildScrollbarTheme(Brightness brightness) {
    // 【核心拦截】：如果是安卓或 iOS 端，直接返回 null，让系统使用原生默认的粗滚动条
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }

    // 只有桌面端才会执行以下的精致样式渲染
    final isLight = brightness == Brightness.light;
    final baseColor = isLight ? Colors.black : Colors.white;

    return ScrollbarThemeData(
      trackColor: WidgetStateProperty.all(Colors.transparent),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      thickness: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return 6.0;
        if (states.contains(WidgetState.dragged)) return 6.0;
        return 3.0;
      }),
      radius: const Radius.circular(8.0),
      crossAxisMargin: 3.0,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged)) return baseColor.withValues(alpha: 0.5);
        if (states.contains(WidgetState.hovered)) return baseColor.withValues(alpha: 0.4);
        return baseColor.withValues(alpha: 0.15);
      }),
      interactive: true,
    );
  }

  // ==========================================
  // 现代拟物风
  // ==========================================
  ThemeData _buildModernTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      // 智能注入滚动条主题 (移动端自动回退到原生)
      scrollbarTheme: _buildScrollbarTheme(brightness),
    );
  }

  // ==========================================
  // 极简扁平风
  // ==========================================
  ThemeData _buildFlatTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final bgColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF121212);
    final surfaceColor = isLight ? const Color(0xFFF5F5F7) : const Color(0xFF1E1E1E);
    final borderColor = isLight ? const Color(0xFFE5E5E5) : const Color(0xFF333333);
    final primaryColor = isLight ? const Color(0xFF111111) : const Color(0xFFEEEEEE);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,

      // 智能注入滚动条主题 (移动端自动回退到原生)
      scrollbarTheme: _buildScrollbarTheme(brightness),

      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
        primary: primaryColor,
        surface: bgColor,
        surfaceContainerHighest: surfaceColor,
        surfaceContainer: isLight ? Colors.white : const Color(0xFF1A1A1A),
        surfaceContainerLow: bgColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: bgColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: isLight ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: isLight ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _seedColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: bgColor,
        indicatorColor: surfaceColor,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}