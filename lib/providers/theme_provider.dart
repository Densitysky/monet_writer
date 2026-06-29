import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { modern, flat, golden }
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
  static const flat = StyleConfig(
    dialogRadius:12,cardRadius:8,chipRadius:4,buttonRadius:6,fabRadius:8,inputRadius:6,showBorder:true,
    fontSizeCaption:12,fontSizeBody:13,fontSizeSubtitle:15,fontSizeTitle:18,fontSizeHeadline:22,
    fontSizeDisplay:26,fontSizeHero:32,
    fontWeightBody:FontWeight.w400,fontWeightEmphasis:FontWeight.w600,
    fontWeightTitle:FontWeight.w700,fontWeightHero:FontWeight.w800,
    lineHeightTight:1.2,lineHeightNormal:1.4,lineHeightRelaxed:1.5,
    spaceXS:4,spaceSM:8,spaceMD:16,spaceLG:24,spaceXL:32,space2XL:48,
    opacityDisabled:0.40,opacityHint:0.25,opacityDivider:0.10,opacityOverlay:0.05,
  );
  /// 金色体系 — 现代/极简/黄金三个风格共享此配置（含金律/中国色/和色三套配色）
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
    AppThemeStyle.flat   => _buildFlatTheme(b),
    AppThemeStyle.golden => _buildGoldenTheme(b, _colorPalette),
    AppThemeStyle.modern => _buildModernTheme(b),
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
    return ThemeData(useMaterial3:true,brightness:b,scaffoldBackgroundColor:cs.surface,colorScheme:cs,extensions:[StyleConfig.golden],scrollbarTheme:_buildScrollbarTheme(b),appBarTheme:AppBarTheme(backgroundColor:cs.surface,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:0,centerTitle:false,titleTextStyle:TextStyle(color:cs.onSurface,fontSize:18,fontWeight:FontWeight.w600)),cardTheme:CardThemeData(color:cs.surfaceContainerLow,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),dialogTheme:DialogThemeData(backgroundColor:cs.surfaceContainerLow,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(elevation:0,backgroundColor:cs.primary,foregroundColor:cs.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),floatingActionButtonTheme:FloatingActionButtonThemeData(elevation:0,focusElevation:0,hoverElevation:0,highlightElevation:0,backgroundColor:cs.primary,foregroundColor:cs.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:cs.surfaceContainerHighest,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide(color:cs.outlineVariant)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide(color:cs.primary,width:2))),navigationBarTheme:NavigationBarThemeData(elevation:0,backgroundColor:cs.surface,indicatorColor:cs.surfaceContainerHighest,indicatorShape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))));
  }

  // ---- 金律 137.5° 色相旋转 ----
  ColorScheme _goldenAngleScheme(Brightness b, bool isLight) {
    final hsl = HSLColor.fromColor(_seedColor);
    return ColorScheme(
      brightness:b, primary:_seedColor, onPrimary:isLight?Colors.white:const Color(0xFF1C1C1A),
      secondary:hsl.withHue((hsl.hue+137.5)%360).withSaturation(hsl.saturation*0.85).withLightness(isLight?0.45:0.65).toColor(),
      onSecondary:isLight?Colors.white:const Color(0xFF1C1C1A),
      tertiary:hsl.withHue((hsl.hue+275)%360).withSaturation(hsl.saturation*0.9).withLightness(isLight?0.40:0.60).toColor(),
      onTertiary:isLight?Colors.white:const Color(0xFF1C1C1A),
      error:const Color(0xFFBA1A1A),onError:Colors.white,
      surface:isLight?hsl.withSaturation(0.05).withLightness(0.98).toColor():hsl.withSaturation(0.04).withLightness(0.10).toColor(),
      onSurface:isLight?const Color(0xFF1C1C1A):const Color(0xFFE2E1DD),
      surfaceContainerHighest:isLight?hsl.withSaturation(0.08).withLightness(0.94).toColor():hsl.withSaturation(0.05).withLightness(0.15).toColor(),
      surfaceContainer:isLight?const Color(0xFFFFFBF8):const Color(0xFF1C1B1A),
      surfaceContainerLow:isLight?const Color(0xFFF5F0EB):const Color(0xFF171615),
      outline:isLight?Colors.grey.shade400:Colors.grey.shade700,
      outlineVariant:isLight?Colors.grey.shade200:Colors.grey.shade800,
    );
  }

  // ---- 中国色 靛青 #1661AB ----
  ColorScheme _chineseScheme(Brightness b, bool isLight) {
    final base = ColorScheme.fromSeed(seedColor:const Color(0xFF1661AB),brightness:b);
    return base.copyWith(
      surface: isLight ? const Color(0xFFFFF8F0) : const Color(0xFF1C1816),
      surfaceContainerLow: isLight ? const Color(0xFFF5EEE6) : const Color(0xFF171312),
      surfaceContainer: isLight ? const Color(0xFFFFFBF5) : const Color(0xFF1C1A18),
      surfaceContainerHighest: isLight ? const Color(0xFFF3EBE3) : const Color(0xFF26211C),
    );
  }

  // ---- 和色 瑠璃 #1E50A2 ----
  ColorScheme _japaneseScheme(Brightness b, bool isLight) {
    final base = ColorScheme.fromSeed(seedColor:const Color(0xFF1E50A2),brightness:b);
    return base.copyWith(
      surface: isLight ? const Color(0xFFFCFAF5) : const Color(0xFF181716),
      surfaceContainerLow: isLight ? const Color(0xFFF5F2ED) : const Color(0xFF161413),
      surfaceContainer: isLight ? const Color(0xFFFAF8F3) : const Color(0xFF1A1817),
      surfaceContainerHighest: isLight ? const Color(0xFFF1EEE9) : const Color(0xFF24211E),
    );
  }

  // ==================== 极简 ====================

  ThemeData _buildFlatTheme(Brightness b) {
    final isLight=b==Brightness.light,bg=isLight?const Color(0xFFFFFFFF):const Color(0xFF121212),surf=isLight?const Color(0xFFF5F5F7):const Color(0xFF1E1E1E),border=isLight?const Color(0xFFE5E5E5):const Color(0xFF333333),primary=isLight?const Color(0xFF111111):const Color(0xFFEEEEEE);
    return ThemeData(useMaterial3:true,brightness:b,scaffoldBackgroundColor:bg,extensions:[StyleConfig.flat],scrollbarTheme:_buildScrollbarTheme(b),colorScheme:ColorScheme.fromSeed(seedColor:_seedColor,brightness:b,surface:bg,surfaceContainerHighest:surf,surfaceContainer:isLight?Colors.white:const Color(0xFF1A1A1A),surfaceContainerLow:bg),appBarTheme:AppBarTheme(backgroundColor:bg,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:0,centerTitle:false,iconTheme:IconThemeData(color:primary),titleTextStyle:TextStyle(color:primary,fontSize:18,fontWeight:FontWeight.w600)),cardTheme:CardThemeData(color:bg,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8),side:BorderSide(color:border,width:1))),dialogTheme:DialogThemeData(backgroundColor:bg,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:BorderSide(color:border,width:1))),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(elevation:0,backgroundColor:primary,foregroundColor:isLight?Colors.white:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)))),floatingActionButtonTheme:FloatingActionButtonThemeData(elevation:0,focusElevation:0,hoverElevation:0,highlightElevation:0,backgroundColor:primary,foregroundColor:isLight?Colors.white:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:surf,border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:BorderSide(color:border)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:BorderSide(color:_seedColor,width:2))),navigationBarTheme:NavigationBarThemeData(elevation:0,backgroundColor:bg,indicatorColor:surf,indicatorShape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))));
  }
}
