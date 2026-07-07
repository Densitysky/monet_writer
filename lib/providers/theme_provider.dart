import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { modern, paper, golden, neumorphic, parchment }
enum ColorPalette { goldenAngle, chinese, japanese }

class StyleConfig extends ThemeExtension<StyleConfig> {
  final double dialogRadius, cardRadius, chipRadius, buttonRadius, fabRadius, inputRadius;
  final double fontSizeCaption, fontSizeBody, fontSizeSubtitle, fontSizeTitle, fontSizeHeadline, fontSizeDisplay, fontSizeHero;
  final FontWeight fontWeightBody, fontWeightEmphasis, fontWeightTitle, fontWeightHero;
  final double lineHeightTight, lineHeightNormal, lineHeightRelaxed;
  final double spaceXS, spaceSM, spaceMD, spaceLG, spaceXL, space2XL;
  final double opacityDisabled, opacityHint, opacityDivider, opacityOverlay;
  final bool showBorder;

  const StyleConfig({
    required this.dialogRadius, required this.cardRadius, required this.chipRadius,
    required this.buttonRadius, required this.fabRadius, required this.inputRadius,
    required this.fontSizeCaption, required this.fontSizeBody, required this.fontSizeSubtitle,
    required this.fontSizeTitle, required this.fontSizeHeadline, required this.fontSizeDisplay, required this.fontSizeHero,
    required this.fontWeightBody, required this.fontWeightEmphasis, required this.fontWeightTitle, required this.fontWeightHero,
    required this.lineHeightTight, required this.lineHeightNormal, required this.lineHeightRelaxed,
    required this.spaceXS, required this.spaceSM, required this.spaceMD, required this.spaceLG, required this.spaceXL, required this.space2XL,
    required this.opacityDisabled, required this.opacityHint, required this.opacityDivider, required this.opacityOverlay,
    this.showBorder = false,
  });

  double get roundedRadius => fabRadius;

  static const modern = StyleConfig(
    dialogRadius:28,cardRadius:12,chipRadius:20,buttonRadius:20,fabRadius:16,inputRadius:12,
    fontSizeCaption:12,fontSizeBody:14,fontSizeSubtitle:16,fontSizeTitle:20,fontSizeHeadline:24,
    fontSizeDisplay:28,fontSizeHero:36,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w500,
    fontWeightTitle:FontWeight.w700,fontWeightHero:FontWeight.w800,
    lineHeightTight:1.2,lineHeightNormal:1.5,lineHeightRelaxed:1.6,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.38,opacityHint:0.20,opacityDivider:0.12,opacityOverlay:0.05,
  );
  static const paper = StyleConfig(
    dialogRadius:12,cardRadius:8,chipRadius:4,buttonRadius:6,fabRadius:8,inputRadius:6,showBorder:true,
    fontSizeCaption:12,fontSizeBody:13,fontSizeSubtitle:15,fontSizeTitle:18,fontSizeHeadline:22,
    fontSizeDisplay:26,fontSizeHero:32,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w600,
    fontWeightTitle:FontWeight.w700,fontWeightHero:FontWeight.w800,
    lineHeightTight:1.2,lineHeightNormal:1.4,lineHeightRelaxed:1.5,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.40,opacityHint:0.25,opacityDivider:0.10,opacityOverlay:0.05,
  );
  /// 金色体系 — 现代/纸感/黄金三个风格共享此配置（含金律/中国色/和色三套配色）
  static const golden = StyleConfig(
    dialogRadius:16,cardRadius:10,chipRadius:12,buttonRadius:12,fabRadius:14,inputRadius:10,
    fontSizeCaption:12,fontSizeBody:14,fontSizeSubtitle:16,fontSizeTitle:20,fontSizeHeadline:24,
    fontSizeDisplay:28,fontSizeHero:36,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w500,
    fontWeightTitle:FontWeight.w700,fontWeightHero:FontWeight.w800,
    lineHeightTight:1.2,lineHeightNormal:1.5,lineHeightRelaxed:1.6,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.38,opacityHint:0.20,opacityDivider:0.12,opacityOverlay:0.05,
  );
  /// Soft UI 新拟态风格 — 白色纸感，浅灰白背景，内外阴影，现代高级感
  static const neumorphic = StyleConfig(
    dialogRadius:20,cardRadius:16,chipRadius:12,buttonRadius:14,fabRadius:18,inputRadius:14,
    fontSizeCaption:12,fontSizeBody:14,fontSizeSubtitle:16,fontSizeTitle:20,fontSizeHeadline:24,
    fontSizeDisplay:28,fontSizeHero:36,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w500,
    fontWeightTitle:FontWeight.w700,fontWeightHero:FontWeight.w800,
    lineHeightTight:1.2,lineHeightNormal:1.5,lineHeightRelaxed:1.6,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.38,opacityHint:0.20,opacityDivider:0.10,opacityOverlay:0.04,
  );
  /// 羊皮纸风格 — 书棕色 #78716C + 琥珀 #D97706 + 纸底 #FFFBEB，学术/书房感
  static const parchment = StyleConfig(
    dialogRadius:12,cardRadius:12,chipRadius:8,buttonRadius:10,fabRadius:14,inputRadius:10,showBorder:true,
    fontSizeCaption:11,fontSizeBody:14,fontSizeSubtitle:16,fontSizeTitle:20,fontSizeHeadline:26,
    fontSizeDisplay:34,fontSizeHero:42,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w500,
    fontWeightTitle:FontWeight.w600,fontWeightHero:FontWeight.w700,
    lineHeightTight:1.3,lineHeightNormal:1.6,lineHeightRelaxed:1.8,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.40,opacityHint:0.25,opacityDivider:0.10,opacityOverlay:0.05,
  );

  @override StyleConfig copyWith({
    double? dialogRadius, double? cardRadius, double? chipRadius, double? buttonRadius, double? fabRadius, double? inputRadius, bool? showBorder,
    double? fontSizeCaption, double? fontSizeBody, double? fontSizeSubtitle, double? fontSizeTitle, double? fontSizeHeadline, double? fontSizeDisplay, double? fontSizeHero,
    FontWeight? fontWeightBody, FontWeight? fontWeightEmphasis, FontWeight? fontWeightTitle, FontWeight? fontWeightHero,
    double? lineHeightTight, double? lineHeightNormal, double? lineHeightRelaxed,
    double? spaceXS, double? spaceSM, double? spaceMD, double? spaceLG, double? spaceXL, double? space2XL,
    double? opacityDisabled, double? opacityHint, double? opacityDivider, double? opacityOverlay,
  }) => StyleConfig(
    dialogRadius: dialogRadius ?? this.dialogRadius, cardRadius: cardRadius ?? this.cardRadius,
    chipRadius: chipRadius ?? this.chipRadius, buttonRadius: buttonRadius ?? this.buttonRadius,
    fabRadius: fabRadius ?? this.fabRadius, inputRadius: inputRadius ?? this.inputRadius, showBorder: showBorder ?? this.showBorder,
    fontSizeCaption: fontSizeCaption ?? this.fontSizeCaption, fontSizeBody: fontSizeBody ?? this.fontSizeBody,
    fontSizeSubtitle: fontSizeSubtitle ?? this.fontSizeSubtitle, fontSizeTitle: fontSizeTitle ?? this.fontSizeTitle,
    fontSizeHeadline: fontSizeHeadline ?? this.fontSizeHeadline, fontSizeDisplay: fontSizeDisplay ?? this.fontSizeDisplay, fontSizeHero: fontSizeHero ?? this.fontSizeHero,
    fontWeightBody: fontWeightBody ?? this.fontWeightBody, fontWeightEmphasis: fontWeightEmphasis ?? this.fontWeightEmphasis,
    fontWeightTitle: fontWeightTitle ?? this.fontWeightTitle, fontWeightHero: fontWeightHero ?? this.fontWeightHero,
    lineHeightTight: lineHeightTight ?? this.lineHeightTight, lineHeightNormal: lineHeightNormal ?? this.lineHeightNormal, lineHeightRelaxed: lineHeightRelaxed ?? this.lineHeightRelaxed,
    spaceXS: spaceXS ?? this.spaceXS, spaceSM: spaceSM ?? this.spaceSM, spaceMD: spaceMD ?? this.spaceMD,
    spaceLG: spaceLG ?? this.spaceLG, spaceXL: spaceXL ?? this.spaceXL, space2XL: space2XL ?? this.space2XL,
    opacityDisabled: opacityDisabled ?? this.opacityDisabled, opacityHint: opacityHint ?? this.opacityHint,
    opacityDivider: opacityDivider ?? this.opacityDivider, opacityOverlay: opacityOverlay ?? this.opacityOverlay,
  );

  @override StyleConfig lerp(ThemeExtension<StyleConfig>? other, double t) => this;
  static StyleConfig of(BuildContext context) => Theme.of(context).extension<StyleConfig>()!;
}

class ThemeProvider extends ChangeNotifier {
  Color _seedColor = const Color(0xFF3A7CA5);
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _themeStyle = AppThemeStyle.modern;
  ColorPalette _colorPalette = ColorPalette.goldenAngle;

  static const List<Color> goldenAngleColors = [
    Color(0xFFE8618C),Color(0xFFE8853A),Color(0xFFD4A017),Color(0xFF2E8B57),
    Color(0xFF3A7CA5),Color(0xFF7B5EA7),Color(0xFFE2B2B1),Color(0xFFC9A96E),
    Color(0xFF8B9A6E),Color(0xFFA0B4C8),Color(0xFF9A8FBF),Color(0xFFB0ADA6),
    Color(0xFF9B2D3C),Color(0xFF8B5E34),Color(0xFF1A6B54),Color(0xFF1B4F72),
    Color(0xFF4A3572),Color(0xFF3D3D3D),Color(0xFFFAFAF8),Color(0xFFF0EFEA),
    Color(0xFFE2E1DD),Color(0xFFB0AEAA),Color(0xFF5C5B57),Color(0xFF1C1C1A),
  ];

  /// 中国传統色 — 24色，取自 zhongguose.com
  static const List<Color> chineseColors = [
    Color(0xFF1661AB),Color(0xFF5A4FCF),Color(0xFF5B8C51),Color(0xFF426647),
    Color(0xFFFFF143),Color(0xFFC89B40),Color(0xFFBF242A),Color(0xFF9D2933),
    Color(0xFFF47983),Color(0xFFDB5A6B),Color(0xFFE4C6D0),Color(0xFFCCA4E3),
    Color(0xFFD6ECF0),Color(0xFFE9F1F6),Color(0xFF424C50),Color(0xFF3D3B4F),
    Color(0xFFFF461F),Color(0xFFED5736),Color(0xFFF7C242),Color(0xFFD9B611),
    Color(0xFF48C0A3),Color(0xFF3B818C),Color(0xFF2E4E7E),Color(0xFF50616D),
  ];

  /// 和色 — 24色，取自 nipponcolors.com
  static const List<Color> japaneseColors = [
    Color(0xFF1E50A2),Color(0xFF2792C3),Color(0xFF99B548),Color(0xFFC3D825),
    Color(0xFFF8B500),Color(0xFFF29929),Color(0xFFDB5A6B),Color(0xFFFEDFE1),
    Color(0xFF674196),Color(0xFF5654A2),Color(0xFFBBBCDE),Color(0xFF243860),
    Color(0xFFF17C67),Color(0xFFEF454A),Color(0xFFFB966E),Color(0xFF98514B),
    Color(0xFF9E8B6F),Color(0xFFFCFAF2),Color(0xFF1C1C1A),Color(0xFF727171),
    Color(0xFF316745),Color(0xFF6E7955),Color(0xFF192F60),Color(0xFF19448E),
  ];

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get themeStyle => _themeStyle;
  ColorPalette get colorPalette => _colorPalette;
  bool get isPaperOrParchment => _themeStyle == AppThemeStyle.paper || _themeStyle == AppThemeStyle.parchment;
  ColorPalette get effectivePalette => _themeStyle == AppThemeStyle.golden ? _colorPalette : ColorPalette.goldenAngle;

  List<Color> get currentPaletteColors => switch (_colorPalette) {
    ColorPalette.goldenAngle => goldenAngleColors,
    ColorPalette.chinese => chineseColors,
    ColorPalette.japanese => japaneseColors,
  };

  /// 所有可用配色（色盘弹窗用）
  static List<Color> get allPaletteColors => [...goldenAngleColors, ...chineseColors, ...japaneseColors];

  ThemeProvider() { _loadPreferences(); }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cv = prefs.getInt('theme_seed_color'); if (cv != null) _seedColor = Color(cv);
      final mi = prefs.getInt('theme_mode'); if (mi != null) _themeMode = ThemeMode.values[mi];
      final si = prefs.getInt('theme_style'); if (si != null) _themeStyle = AppThemeStyle.values[si];
      final pi = prefs.getInt('theme_color_palette'); if (pi != null) _colorPalette = ColorPalette.values[pi];
      notifyListeners();
    } catch (e) { debugPrint("加载主题设置失败: $e"); }
  }

  Future<void> setSeedColor(Color color) async { _seedColor = color; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setInt('theme_seed_color', color.toARGB32()); }
  Future<void> setThemeMode(ThemeMode mode) async { _themeMode = mode; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setInt('theme_mode', mode.index); }
  Future<void> setThemeStyle(AppThemeStyle style) async { _themeStyle = style; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setInt('theme_style', style.index); }
  Future<void> setColorPalette(ColorPalette palette) async { _colorPalette = palette; notifyListeners(); final p = await SharedPreferences.getInstance(); await p.setInt('theme_color_palette', palette.index); }

  ThemeData get lightTheme => _chooseTheme(Brightness.light);
  ThemeData get darkTheme => _chooseTheme(Brightness.dark);
  ThemeData _chooseTheme(Brightness b) => switch (_themeStyle) {
    AppThemeStyle.paper  => _buildPaperTheme(b),
    AppThemeStyle.golden => _buildGoldenTheme(b, _colorPalette),
    AppThemeStyle.modern => _buildModernTheme(b),
    AppThemeStyle.neumorphic => _buildSoftUiTheme(b),
    AppThemeStyle.parchment => _buildParchmentTheme(b),
  };

  ScrollbarThemeData? _buildScrollbarTheme(Brightness b) {
    if (Platform.isAndroid || Platform.isIOS) return null;
    final base = b == Brightness.light ? Colors.black : Colors.white;
    return ScrollbarThemeData(trackColor:WidgetStateProperty.all(Colors.transparent),trackBorderColor:WidgetStateProperty.all(Colors.transparent),thickness:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.hovered)||s.contains(WidgetState.dragged)?6.0:3.0),radius:const Radius.circular(8),crossAxisMargin:3,thumbColor:WidgetStateProperty.resolveWith((s){if(s.contains(WidgetState.dragged))return base.withValues(alpha:0.5);if(s.contains(WidgetState.hovered))return base.withValues(alpha:0.4);return base.withValues(alpha:0.15);}),interactive:true);
  }

  // ==================== 风格体系 Builder ====================

  ThemeData _buildModernTheme(Brightness b) {
    final cs = ColorScheme.fromSeed(seedColor:_seedColor,brightness:b);
    return ThemeData(useMaterial3:true,brightness:b,colorScheme:cs,extensions:[StyleConfig.modern],scrollbarTheme:_buildScrollbarTheme(b),appBarTheme:AppBarTheme(backgroundColor:cs.surface,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:1,centerTitle:false,titleTextStyle:TextStyle(color:cs.onSurface,fontSize:18,fontWeight:FontWeight.w600)),cardTheme:CardThemeData(color:cs.surfaceContainerLow,elevation:1,surfaceTintColor:cs.primary.withValues(alpha:0.05),margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),dialogTheme:DialogThemeData(backgroundColor:cs.surfaceContainerLow,elevation:2,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:cs.primary,foregroundColor:cs.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)))),floatingActionButtonTheme:FloatingActionButtonThemeData(backgroundColor:cs.primaryContainer,foregroundColor:cs.onPrimaryContainer,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:cs.surfaceContainerHighest,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:cs.outline)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:cs.primary,width:2))),navigationBarTheme:NavigationBarThemeData(elevation:0,backgroundColor:cs.surface,indicatorColor:cs.secondaryContainer,indicatorShape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))));
  }

  ThemeData _buildGoldenTheme(Brightness b, ColorPalette palette) {
    final isLight = b == Brightness.light;
    final cs = switch (palette) {
      ColorPalette.goldenAngle => _goldenAngleScheme(b, isLight),
      ColorPalette.chinese    => _chineseScheme(b, isLight),
      ColorPalette.japanese   => _japaneseScheme(b, isLight),
    };
    return ThemeData(useMaterial3:true,brightness:b,scaffoldBackgroundColor:cs.surface,colorScheme:cs,extensions:[StyleConfig.golden],scrollbarTheme:_buildScrollbarTheme(b),appBarTheme:AppBarTheme(backgroundColor:cs.surface,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:0,centerTitle:false,titleTextStyle:TextStyle(color:cs.onSurface,fontSize:18,fontWeight:FontWeight.w600)),cardTheme:CardThemeData(color:cs.secondaryContainer,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),dialogTheme:DialogThemeData(backgroundColor:cs.secondaryContainer,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(elevation:0,backgroundColor:cs.primary,foregroundColor:cs.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),floatingActionButtonTheme:FloatingActionButtonThemeData(elevation:0,focusElevation:0,hoverElevation:0,highlightElevation:0,backgroundColor:cs.primary,foregroundColor:cs.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:cs.surfaceContainerHighest,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide(color:cs.outlineVariant)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide(color:cs.primary,width:2))),navigationBarTheme:NavigationBarThemeData(elevation:0,backgroundColor:cs.surface,indicatorColor:cs.surfaceContainerHighest,indicatorShape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))));
  }

  // ---- 金律 137.5° 色相旋转 ----
  ColorScheme _goldenAngleScheme(Brightness b, bool isLight) {
    final hsl = HSLColor.fromColor(_seedColor);
    final sec = hsl.withHue((hsl.hue+137.5)%360).withSaturation(hsl.saturation*0.85).withLightness(isLight?0.45:0.65).toColor();
    final ter = hsl.withHue((hsl.hue+275)%360).withSaturation(hsl.saturation*0.9).withLightness(isLight?0.40:0.60).toColor();
    // --- 60:30:10 黄金配色比例 ---
    // 30%层：secondaryContainer = 浅暖色底，用于卡片/选区背景
    final secContainer = isLight
        ? hsl.withHue((hsl.hue+137.5)%360).withSaturation(0.12).withLightness(0.94).toColor()
        : hsl.withHue((hsl.hue+137.5)%360).withSaturation(0.08).withLightness(0.16).toColor();
    final onSecContainer = isLight
        ? hsl.withHue((hsl.hue+137.5)%360).withSaturation(0.30).withLightness(0.22).toColor()
        : hsl.withHue((hsl.hue+137.5)%360).withSaturation(0.10).withLightness(0.90).toColor();
    // 分隔线暖金
    final dividerColor = isLight
        ? const Color(0x30BF9540)
        : const Color(0x20BF9540);
    return ColorScheme(
      brightness:b, primary:_seedColor, onPrimary:isLight?Colors.white:const Color(0xFF1C1C1A),
      secondary:sec, onSecondary:isLight?Colors.white:const Color(0xFF1C1C1A),
      secondaryContainer:secContainer, onSecondaryContainer:onSecContainer,
      tertiary:ter, onTertiary:isLight?Colors.white:const Color(0xFF1C1C1A),
      error:const Color(0xFFBA1A1A),onError:Colors.white,
      surface:isLight?hsl.withSaturation(0.05).withLightness(0.98).toColor():hsl.withSaturation(0.04).withLightness(0.10).toColor(),
      onSurface:isLight?const Color(0xFF1C1C1A):const Color(0xFFE2E1DD),
      surfaceContainerHighest:isLight?hsl.withSaturation(0.08).withLightness(0.94).toColor():hsl.withSaturation(0.05).withLightness(0.15).toColor(),
      surfaceContainer:isLight?const Color(0xFFFFFBF8):const Color(0xFF1C1B1A),
      surfaceContainerLow:isLight?const Color(0xFFF5F0EB):const Color(0xFF171615),
      outline:isLight?Colors.grey.shade400:Colors.grey.shade700,
      outlineVariant:dividerColor,
    );
  }

  // ---- 中国色 纸感暖底 + 用户主题色 ----
  ColorScheme _chineseScheme(Brightness b, bool isLight) {
    final base = ColorScheme.fromSeed(seedColor: _seedColor, brightness: b);
    // 30% 层：用用户主题色做极淡暖色底，避免跟暖纸背景冲突
    final hslSeed = HSLColor.fromColor(_seedColor);
    final secContainer = hslSeed
        .withSaturation(hslSeed.saturation * 0.2)
        .withLightness(isLight ? 0.93 : 0.18)
        .toColor();
    return base.copyWith(
      surface: isLight ? const Color(0xFFFFF8F0) : const Color(0xFF1C1816),
      surfaceContainerLow: isLight ? const Color(0xFFF5EEE6) : const Color(0xFF171312),
      surfaceContainer: isLight ? const Color(0xFFFFFBF5) : const Color(0xFF1C1A18),
      surfaceContainerHighest: isLight ? const Color(0xFFF3EBE3) : const Color(0xFF26211C),
      secondaryContainer: secContainer,
      onSecondaryContainer: base.onSecondary,
      outlineVariant: const Color(0x30BF9540),
    );
  }

  // ---- 和色 纸感暖底 + 用户主题色 ----
  ColorScheme _japaneseScheme(Brightness b, bool isLight) {
    final base = ColorScheme.fromSeed(seedColor: _seedColor, brightness: b);
    // 30% 层：用用户主题色做极淡暖色底
    final hslSeed = HSLColor.fromColor(_seedColor);
    final secContainer = hslSeed
        .withSaturation(hslSeed.saturation * 0.2)
        .withLightness(isLight ? 0.93 : 0.18)
        .toColor();
    return base.copyWith(
      surface: isLight ? const Color(0xFFFCFAF5) : const Color(0xFF181716),
      surfaceContainerLow: isLight ? const Color(0xFFF5F2ED) : const Color(0xFF161413),
      surfaceContainer: isLight ? const Color(0xFFFAF8F3) : const Color(0xFF1A1817),
      surfaceContainerHighest: isLight ? const Color(0xFFF1EEE9) : const Color(0xFF24211E),
      secondaryContainer: secContainer,
      onSecondaryContainer: base.onSecondary,
      outlineVariant: const Color(0x30BF9540),
    );
  }

  // ==================== Soft UI 新拟态 ====================

  /// Soft UI 新拟态风格 —— 浅灰白背景，内外浮雕阴影，柔和克制。
  /// 视觉特征：卡片凸起（双色阴影）、输入框凹陷（内阴影）、毛玻璃面板。
  ThemeData _buildSoftUiTheme(Brightness b) {
    final isLight = b == Brightness.light;
    // 参考图同款冷灰白背景：比纯白柔和、比中灰明亮
    final bg     = isLight ? const Color(0xFFEDF0F4) : const Color(0xFF161618);
    // 卡片表面略亮于背景，让阴影只负责"轻抬"效果
    final surf   = isLight ? const Color(0xFFF5F7FA) : const Color(0xFF202023);
    final surfHi = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF2A2A2E);
    final onBg   = isLight ? const Color(0xFF4A5568) : const Color(0xFFE8E8EA);
    // 柔和模式仍要读取用户设置的主题色作为 primary；深色模式用浅灰
    final primary = isLight ? _seedColor : const Color(0xFFC2C9D6);
    final onPrimary = _contrastColor(primary);
    final outline = isLight ? const Color(0xFFDDE2E9) : const Color(0x1FFFFFFF);

    // Neumorphic 阴影：参考图同款"冷灰蓝柔影"
    // 特征：高 blur/offset 比（约 4:1），低饱和度冷灰，肉眼可见但不抢眼
    final highlight = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF58585A);
    final shadow    = isLight ? const Color(0xFFC5CEDC) : const Color(0xFF0A0A0B);

    final cs = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      surface: bg,
      onSurface: onBg,
      surfaceContainerHighest: surfHi,
      surfaceContainer: surfHi,
      surfaceContainerLow: surf,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: outline,
      outlineVariant: outline,
      shadow: shadow,
      // NavigationBar 选中指示器与图标对比色
      secondaryContainer: surf,
      onSecondaryContainer: onBg,
    );

    return ThemeData(
      useMaterial3: true, brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: cs,
      extensions: const [StyleConfig.neumorphic],
      scrollbarTheme: _buildScrollbarTheme(b),
      appBarTheme: AppBarTheme(
        backgroundColor: bg, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        iconTheme: IconThemeData(color: onBg),
        titleTextStyle: TextStyle(color: onBg, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      // 卡片凸起浮雕效果：elevation>0 才能触发 shadowColor 渲染
      // surfaceTintColor 置透明，避免 Material 3 给卡片罩上一层奇怪的色调
      cardTheme: CardThemeData(
        color: surf, elevation: 3, margin: EdgeInsets.zero,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf, elevation: 4,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0, backgroundColor: primary, foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0, backgroundColor: surfHi, foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      // 输入框凹陷效果：深色 fillColor + 内阴影（通过更低亮度实现）
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfHi,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0, backgroundColor: bg, indicatorColor: surfHi,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        // 明确指定选中/未选中图标与标签颜色，避免 M3 默认用 onSecondaryContainer 导致白底白字
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? onBg : onBg.withValues(alpha: 0.55);
          return IconThemeData(color: color, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? onBg : onBg.withValues(alpha: 0.55);
          return TextStyle(color: color, fontSize: 12);
        }),
      ),
    );
  }

  /// Soft UI 凸起卡片阴影（neumorphic convex shadow）
  /// 用法：BoxDecoration(boxShadow: ThemeProvider.neumorphicConvexShadow(context))
  static List<BoxShadow> neumorphicConvexShadow(BuildContext context, {bool isDark = false}) {
    return isDark
        ? const [
            BoxShadow(color: Color(0xFF5E5E60), offset: Offset(-6, -6), blurRadius: 20),
            BoxShadow(color: Color(0xFF0A0A0B), offset: Offset(8, 8), blurRadius: 24),
          ]
        : const [
            // 参考图同款：大白光高光 + 冷灰蓝柔影，blur/offset 约 4:1
            BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 20),
            BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(6, 6), blurRadius: 24),
          ];
  }

  /// Soft UI 凹陷输入框阴影（neumorphic concave shadow）
  static List<BoxShadow> neumorphicConcaveShadow(BuildContext context, {bool isDark = false}) {
    return isDark
        ? const [
            BoxShadow(color: Color(0xFF0A0A0B), offset: Offset(-3, -3), blurRadius: 5),
            BoxShadow(color: Color(0xFF48484A), offset: Offset(3, 3), blurRadius: 5),
          ]
        : const [
            BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(-3, -3), blurRadius: 5),
            BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(3, 3), blurRadius: 5),
          ];
  }

  // 根据颜色亮度自动返回黑/白对比色
  static Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // ==================== 纸感 ====================

  ThemeData _buildPaperTheme(Brightness b) {
    final isLight = b == Brightness.light;
    // 米纸底色 + 深棕文字，模拟真实纸张
    final bg   = isLight ? const Color(0xFFFBF7F0) : const Color(0xFF1C1A16);
    final surf = isLight ? const Color(0xFFF4EDE4) : const Color(0xFF25211C);
    final onBg = isLight ? const Color(0xFF3C2A1A) : const Color(0xFFE8DDD0);
    final muted  = isLight ? const Color(0xFF8B775A) : const Color(0xFF9A8B75);
    final divid = isLight ? const Color(0x1A8B775A) : const Color(0x1AE8DDD0);
    final primary = _seedColor;
    final onPrimary = _contrastColor(primary);

    final cs = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: onPrimary,
      secondary: const Color(0xFF8B775A),
      onSecondary: isLight ? Colors.white : const Color(0xFF1C1A16),
      surface: bg,
      onSurface: onBg,
      surfaceContainerHighest: surf,
      surfaceContainer: surf,
      surfaceContainerLow: bg,
      primaryContainer: primary.withValues(alpha: 0.15),
      secondaryContainer: const Color(0xFF8B775A).withValues(alpha: 0.12),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: muted,
      outlineVariant: divid,
    );

    return ThemeData(
      useMaterial3: true, brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: cs,
      extensions: const [StyleConfig.paper],
      scrollbarTheme: _buildScrollbarTheme(b),
      appBarTheme: AppBarTheme(
        backgroundColor: bg, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        iconTheme: IconThemeData(color: onBg),
        titleTextStyle: TextStyle(color: onBg, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0, backgroundColor: primary, foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0, focusElevation: 0, hoverElevation: 0, highlightElevation: 0,
        backgroundColor: primary, foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surf,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: muted.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primary, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0, backgroundColor: bg, indicatorColor: surf,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---- 羊皮纸 Parchment — 书棕色 + 琥珀 + 纸底 ----
  ThemeData _buildParchmentTheme(Brightness b) {
    final isLight = b == Brightness.light;
    final bg   = isLight ? const Color(0xFFFBF8F1) : const Color(0xFF1C1814);
    final surf = isLight ? const Color(0xFFF5F1E6) : const Color(0xFF25201C);
    final onBg = isLight ? const Color(0xFF3C2A1A) : const Color(0xFFEBE5D9);
    final muted  = isLight ? const Color(0xFF8B775A) : const Color(0xFF9A8B75);
    final divid = isLight ? const Color(0x1A8B775A) : const Color(0x1AEBE5D9);
    final secondary = isLight ? const Color(0xFF92400E) : const Color(0xFFD4A76A);
    final accent = const Color(0xFFD97706);
    final primary = _seedColor;

    final cs = ColorScheme(
      brightness: b,
      primary: primary.withValues(alpha: isLight ? 1.0 : 0.9),
      onPrimary: isLight ? Colors.white : const Color(0xFF1C1814),
      secondary: secondary,
      onSecondary: isLight ? Colors.white : const Color(0xFF1C1814),
      surface: bg,
      onSurface: onBg,
      surfaceContainerHighest: surf,
      surfaceContainer: surf,
      surfaceContainerLow: bg,
      primaryContainer: accent.withValues(alpha: 0.12),
      secondaryContainer: secondary.withValues(alpha: isLight ? 0.08 : 0.15),
      onSecondaryContainer: isLight ? secondary : const Color(0xFFEBE5D9),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: muted,
      outlineVariant: divid,
    );

    return ThemeData(
      useMaterial3: true, brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: cs,
      extensions: const [StyleConfig.parchment],
      scrollbarTheme: _buildScrollbarTheme(b),
      appBarTheme: AppBarTheme(
        backgroundColor: bg, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        iconTheme: IconThemeData(color: onBg),
        titleTextStyle: TextStyle(color: onBg, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: bg, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: divid, width: 0.5)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0, backgroundColor: accent, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0, focusElevation: 0, hoverElevation: 0, highlightElevation: 0,
        backgroundColor: accent, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surf,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: divid)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0, backgroundColor: bg, indicatorColor: accent.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

