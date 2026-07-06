import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:monet_writer/services/database_service.dart';

/// 写作页面（编辑器）的阅读/写作配色主题。
///
/// 与 [ThemeProvider]（系统设置中的 AppThemeStyle）是**两套独立体系**：
/// - WritingTheme → 写作页编辑器背景/文字/光标色
/// - ThemeProvider → 全局 Material UI 组件样式（卡片/按钮/对话框/导航栏）
///
/// 字段说明：
/// - [backgroundColor]：写作页编辑器背景色（仅影响写作页面，不影响系统 UI）
/// - [textColor]：写作页正文字体色
/// - [cursorColor]：光标颜色
/// - [outlineColor]：编辑器内分隔线色
class WritingTheme {
  final String name;

  /// 【写作页专用】编辑器背景色。非系统主题背景，不要与其他页面的 ThemeData.scaffoldBackgroundColor 混淆。
  final Color backgroundColor;

  final Color textColor;
  final Color cursorColor;
  final Color outlineColor;

  const WritingTheme(this.name, this.backgroundColor, this.textColor, {this.cursorColor = Colors.blue, this.outlineColor = Colors.grey});
}

class UserProvider extends ChangeNotifier {
  // --- 核心数据 ---
  String _nickname = "莫纳书友";
  String? _avatarPath;
  String? _backgroundPath;
  String? _profileCoverPath;

  // --- 统计数据 ---
  int _totalWords = 0;
  int _todayWords = 0;
  int _consecutiveDays = 0;

  // --- 外观设置 ---
  bool _isBackgroundBlurred = true;
  double _fontSize = 18.0;
  double _lineHeight = 1.8;
  // 【新增】：全局段落间距变量，默认 16.0 像素的呼吸感
  double _paragraphSpacing = 16.0;
  int _immersiveTitleStyle = 1; // 0=极简 1=细线 2=角标 3=日式 4=卡片
  int _desktopImmersiveStyle = 0; // 0=纸页画布 1=聚焦光束 2=氛围光晕 3=打字机 4=工作室
  String _fontFamily = 'System';
  String? _customFontPath;
  int _themeIndex = 0;

  // ================= 境界成就系统 =================
  int _titleSystemIndex = 0;
  List<String> _customTitles = [
    'Lv.1 自定义一', 'Lv.2 自定义二', 'Lv.3 自定义三', 'Lv.4 自定义四', 'Lv.5 自定义五',
    'Lv.6 自定义六', 'Lv.7 自定义七', 'Lv.8 自定义八', 'Lv.9 自定义九'
  ];

  static const List<List<String>> presetTitles = [
    ['Lv.1 炼气期', 'Lv.2 筑基期', 'Lv.3 金丹期', 'Lv.4 元婴期', 'Lv.5 化神期', 'Lv.6 炼虚期', 'Lv.7 合体期', 'Lv.8 大乘期', 'Lv.9 渡劫仙尊'],
    ['Lv.1 萌新扑街', 'Lv.2 签约作者', 'Lv.3 上架作者', 'Lv.4 精品作者', 'Lv.5 万订大佬', 'Lv.6 荣耀一星', 'Lv.7 荣耀五星', 'Lv.8 白金大神', 'Lv.9 网文泰斗'],
    ['Lv.1 魔法学徒', 'Lv.2 见习法师', 'Lv.3 初级法师', 'Lv.4 中级法师', 'Lv.5 高级法师', 'Lv.6 大魔法师', 'Lv.7 魔导师', 'Lv.8 大魔导师', 'Lv.9 法神'],
    ['Lv.1 波纹使者', 'Lv.2 替身觉醒', 'Lv.3 替身使者', 'Lv.4 远距离型', 'Lv.5 近战力量型', 'Lv.6 时间系替身', 'Lv.7 镇魂曲形态', 'Lv.8 天堂制造', 'Lv.9 超越天堂'],
    ['Lv.1 无名小卒', 'Lv.2 初入江湖', 'Lv.3 后起之秀', 'Lv.4 武林高手', 'Lv.5 一方豪杰', 'Lv.6 宗师风范', 'Lv.7 武林盟主', 'Lv.8 绝世高手', 'Lv.9 天下第一'],
    ['Lv.1 行星文明', 'Lv.2 恒星文明', 'Lv.3 星际殖民', 'Lv.4 银河联邦', 'Lv.5 超空间航行', 'Lv.6 维度跃迁', 'Lv.7 宇宙主宰', 'Lv.8 多元宇宙', 'Lv.9 创世神级'],
  ];

  static const int customTitleIndex = 6;

  static const List<Map<String, String>> systemInfo = [
    {'name': '东方修仙', 'subtitle': '炼气 · 筑基 · 金丹…', 'icon': 'drag_indicator'},
    {'name': '网文作家', 'subtitle': '萌新 · 签约 · 万订…', 'icon': 'edit_note'},
    {'name': '西幻魔法', 'subtitle': '学徒 · 法师 · 法神…', 'icon': 'auto_awesome'},
    {'name': 'JOJO替身', 'subtitle': '波纹 · 替身 · 天堂…', 'icon': 'bolt'},
    {'name': '武侠江湖', 'subtitle': '小卒 · 高手 · 盟主…', 'icon': 'sports_kabaddi'},
    {'name': '科幻星际', 'subtitle': '行星 · 银河 · 创世…', 'icon': 'rocket_launch'},
    {'name': '完全自定义', 'subtitle': '随心所欲命名', 'icon': 'edit'},
  ];

  int get titleSystemIndex => _titleSystemIndex;
  List<String> get customTitles => _customTitles;

  int get currentLevelIndex {
    if (_totalWords < 10000) return 0;
    if (_totalWords < 50000) return 1;
    if (_totalWords < 150000) return 2;
    if (_totalWords < 500000) return 3;
    if (_totalWords < 1000000) return 4;
    if (_totalWords < 2000000) return 5;
    if (_totalWords < 5000000) return 6;
    if (_totalWords < 10000000) return 7;
    return 8;
  }

  String get currentLevelTitle {
    final index = currentLevelIndex;
    if (_titleSystemIndex == customTitleIndex) return _customTitles[index];
    return presetTitles[_titleSystemIndex][index];
  }
  // ==========================================================

  // ═══════════════════════════════════════════════════════════
  // 写作主题列表
  //
  // 设计原则（借鉴 Material Color Utilities HCT 体系）：
  // HCT = Hue(0-360) + Chroma(0-∞) + Tone(0-100)
  // 核心思想：从单一 seed color 沿 Tone 轴派生整条调色板。
  // - TonalPalette: 固定 Hue+Chroma，Tone 0→100 生成 13 个层级
  // - light scheme: background=T99, surface=T99, primary=T40, outline=T50
  // - 每个辅助色（分隔线、阴影、禁用色）不是随意搭配，而是同一个 hue
  //   在不同 tone 下的自然变体，确保视觉和谐。
  //
  // 对本项目的实践意义：
  // 新增主题时，在定义主色后，辅助色（outlineColor、阴影透明度）
  // 应沿主色的 Hue 方向推导，避免引入冲突色相。
  // ═══════════════════════════════════════════════════════════
  static const List<WritingTheme> themes = [
    WritingTheme('默认白', Color(0xFFFAFAFA), Colors.black87),
    WritingTheme('护眼绿', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    WritingTheme('羊皮纸', Color(0xFFFDF5E6), Color(0xFF5D4037)),
    WritingTheme('暗夜黑', Color(0xFF1E1E1E), Color(0xFFB0BEC5), cursorColor: Colors.white, outlineColor: Colors.grey),
    WritingTheme('深海蓝', Color(0xFF102027), Color(0xFFCFD8DC), cursorColor: Colors.cyan),
    WritingTheme('Soft UI', Color(0xFFEBECED), Color(0xFF2C2C2E),
        cursorColor: Color(0xFF8E8E93),
        outlineColor: Color(0xFFC6C6C8)),
  ];

  String get nickname => _nickname;
  String? get avatarPath => _avatarPath;
  String? get backgroundPath => _backgroundPath;
  String? get profileCoverPath => _profileCoverPath;
  String? get backgroundImagePath => (_backgroundPath != null && File(_backgroundPath!).existsSync()) ? _backgroundPath : null;

  int get totalWords => _totalWords;
  int get todayWords => _todayWords;
  int get consecutiveDays => _consecutiveDays;
  bool get isBackgroundBlurred => _isBackgroundBlurred;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  // 【新增】：对外暴漏 Getter
  double get paragraphSpacing => _paragraphSpacing;
  int get immersiveTitleStyle => _immersiveTitleStyle;
  int get desktopImmersiveStyle => _desktopImmersiveStyle;
  String get fontFamily => _fontFamily;

  /// 返回可直接用于 TextStyle.fontFamily 的有效字体族
  /// System → null（系统默认）, NotoSerifSC → 'serif'（系统衬线体）, 其他 → 原值
  String? get effectiveFontFamily {
    switch (_fontFamily) {
      case 'System':
        return null;
      case 'NotoSerifSC':
        return 'serif';
      default:
        return _fontFamily;
    }
  }

  int get themeIndex => _themeIndex;
  WritingTheme get currentTheme => themes[_themeIndex];

  PaletteGenerator? _paletteGenerator;
  Color get primaryColor => _paletteGenerator?.dominantColor?.color ?? Colors.blue;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    _nickname = prefs.getString('user_nickname') ?? "莫纳书友";
    _avatarPath = prefs.getString('user_avatar_path');
    _backgroundPath = prefs.getString('user_bg_path');
    _profileCoverPath = prefs.getString('user_profile_cover_path');

    if (_backgroundPath == _avatarPath) _backgroundPath = null;

    _titleSystemIndex = prefs.getInt('setting_title_system') ?? 0;
    _customTitles = prefs.getStringList('setting_custom_titles') ?? _customTitles;

    await refreshStats();

    _isBackgroundBlurred = prefs.getBool('setting_bg_blur') ?? true;
    _fontSize = prefs.getDouble('setting_font_size') ?? 18.0;
    _lineHeight = prefs.getDouble('setting_line_height') ?? 1.8;
    // 【新增】：启动时从本地磁盘加载用户设定的段距
    _paragraphSpacing = prefs.getDouble('setting_paragraph_spacing') ?? 16.0;
    _immersiveTitleStyle = prefs.getInt('setting_immersive_title_style') ?? 1;
    _desktopImmersiveStyle = prefs.getInt('setting_desktop_immersive_style') ?? 0;
    _fontFamily = prefs.getString('setting_font_family') ?? 'System';
    _customFontPath = prefs.getString('setting_font_path');
    _themeIndex = prefs.getInt('setting_theme_index') ?? 0;

    if (_customFontPath != null && File(_customFontPath!).existsSync()) {
      await _loadFontToEngine(_customFontPath!);
    }
    if (_avatarPath != null) await _updatePalette();
    notifyListeners();
  }

  Future<void> refreshStats() async {
    final db = DatabaseService();
    _todayWords = await db.getTodayWordCount();
    _totalWords = await db.getTotalWordCount();
    _consecutiveDays = await db.getConsecutiveDays();
    notifyListeners();
  }

  Future<void> setTitleSystemIndex(int index) async {
    _titleSystemIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('setting_title_system', index);
    notifyListeners();
  }

  Future<void> updateCustomTitles(List<String> titles) async {
    _customTitles = titles;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('setting_custom_titles', titles);
    notifyListeners();
  }

  Future<void> updateNickname(String name) async {
    _nickname = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', name);
    notifyListeners();
  }
  Future<void> setNickname(String name) => updateNickname(name);

  Future<void> updateProfileCoverPath(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = await File(path).copy('${directory.path}/cover_$timestamp.jpg');
      _profileCoverPath = savedFile.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_cover_path', _profileCoverPath!);
      notifyListeners();
    } catch (e) { debugPrint("横幅保存失败: $e"); }
  }

  Future<void> setProfileCoverPath(String? path) async {
    if (path == null) {
      _profileCoverPath = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_cover_path');
      notifyListeners();
    } else {
      await updateProfileCoverPath(path);
    }
  }

  // 【核心修改】：在配置更新引擎中加入 paragraphSpacing 参数
  Future<void> updateWritingConfig({double? fontSize, double? lineHeight, double? paragraphSpacing}) async {
    final prefs = await SharedPreferences.getInstance();
    if (fontSize != null) { _fontSize = fontSize; await prefs.setDouble('setting_font_size', fontSize); }
    if (lineHeight != null) { _lineHeight = lineHeight; await prefs.setDouble('setting_line_height', lineHeight); }
    if (paragraphSpacing != null) { _paragraphSpacing = paragraphSpacing; await prefs.setDouble('setting_paragraph_spacing', paragraphSpacing); }
    notifyListeners();
  }
  Future<void> setFontSize(double size) => updateWritingConfig(fontSize: size);
  Future<void> setLineHeight(double height) => updateWritingConfig(lineHeight: height);
  Future<void> setParagraphSpacing(double spacing) => updateWritingConfig(paragraphSpacing: spacing);

  Future<void> setImmersiveTitleStyle(int style) async {
    _immersiveTitleStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('setting_immersive_title_style', style);
  }

  Future<void> setDesktopImmersiveStyle(int style) async {
    _desktopImmersiveStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('setting_desktop_immersive_style', style);
  }

  Future<void> setFontFamily(String font) async {
    _fontFamily = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_font_family', font);
    notifyListeners();
  }

  Future<void> resetFont() async {
    await setFontFamily('System');
    _customFontPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setting_font_path');
    notifyListeners();
  }

  Future<void> loadLocalFont() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ttf', 'otf']);
      if (result != null) {
        File file = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final savedFile = await file.copy('${directory.path}/custom_font${p.extension(file.path)}');
        _customFontPath = savedFile.path;
        await _loadFontToEngine(_customFontPath!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('setting_font_path', _customFontPath!);
        await setFontFamily('CustomFont');
      }
    } catch (e) { debugPrint("字体导入失败: $e"); }
  }

  Future<void> updateTheme(int index) async {
    if (index >= 0 && index < themes.length) {
      _themeIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('setting_theme_index', index);
      notifyListeners();
    }
  }

  Future<void> toggleBackgroundBlur(bool val) async {
    _isBackgroundBlurred = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_bg_blur', val);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    _backgroundPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('user_bg_path');
    } else {
      await prefs.setString('user_bg_path', path);
    }
    notifyListeners();
  }

  Future<void> _loadFontToEngine(String path) async {
    try {
      File file = File(path);
      var fontData = await file.readAsBytes();
      String fontName = 'CustomFont';
      var fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      _fontFamily = fontName;
    } catch (e) { debugPrint("注册字体失败: $e"); }
  }

  Future<void> updateAvatarPath(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = await File(path).copy('${directory.path}/avatar_$timestamp.jpg');
      _avatarPath = savedFile.path;
      await _updatePalette();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_path', _avatarPath!);
      notifyListeners();
    } catch (e) { debugPrint("头像保存失败: $e"); }
  }

  Future<void> _updatePalette() async {
    if (_avatarPath == null) return;
    try {
      _paletteGenerator = await PaletteGenerator.fromImageProvider(FileImage(File(_avatarPath!)), maximumColorCount: 20);
    } catch (e) { debugPrint("调色板生成失败: $e"); }
  }
}