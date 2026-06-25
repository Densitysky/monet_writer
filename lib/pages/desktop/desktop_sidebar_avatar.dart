import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

class DesktopSidebarAvatar extends StatefulWidget {
  const DesktopSidebarAvatar({super.key});
  @override
  State<DesktopSidebarAvatar> createState() => _DesktopSidebarAvatarState();
}

class _DesktopSidebarAvatarState extends State<DesktopSidebarAvatar> {
  bool _isHovered = false;

  Future<void> _pickAndCropAvatar(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      if (!context.mounted) return;

      final croppedPath = await showDialog<String>(
        context: context, barrierDismissible: false,
        builder: (ctx) => _DesktopCropDialog(imagePath: result.files.single.path!),
      );

      if (croppedPath != null && context.mounted) {
        await context.read<UserProvider>().updateAvatarPath(croppedPath);
      }
    } catch (e) { debugPrint('更新头像失败: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;

    final scaffoldBgColor = isFlat ? Theme.of(context).scaffoldBackgroundColor : currentTheme.backgroundColor;
    final avatarDominantColor = userProvider.primaryColor;
    final avatarPath = userProvider.avatarPath;
    final nickname = userProvider.nickname ?? '创作者';

    // 【核心新增】：实时读取动态成就头衔
    final levelTitle = userProvider.currentLevelTitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _pickAndCropAvatar(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [avatarDominantColor.withValues(alpha: 0.85), avatarDominantColor.withValues(alpha: 0.15)]),
                boxShadow: isFlat ? null : [BoxShadow(color: avatarDominantColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(3.0),
              child: AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack,
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: scaffoldBgColor, border: Border.all(color: scaffoldBgColor, width: 3.0)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipOval(child: (avatarPath != null && avatarPath.isNotEmpty) ? Image.file(File(avatarPath), fit: BoxFit.cover) : Icon(CupertinoIcons.person_solid, size: 54, color: avatarDominantColor.withValues(alpha: 0.4))),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200), opacity: _isHovered ? 1.0 : 0.0,
                        child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.4)), child: const Center(child: Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 28))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(nickname, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: currentTheme.textColor, letterSpacing: 1.0)),
        const SizedBox(height: 8),

        // 【核心新增】：左侧边栏专属动态徽章
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: avatarDominantColor.withValues(alpha: isFlat ? 0.08 : 0.15),
            borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
            border: Border.all(color: avatarDominantColor.withValues(alpha: isFlat ? 0.2 : 0.3)),
          ),
          child: Text(
            levelTitle,
            style: TextStyle(color: isFlat ? currentTheme.textColor : avatarDominantColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}

class _DesktopCropDialog extends StatefulWidget {
  final String imagePath;
  const _DesktopCropDialog({required this.imagePath});
  @override
  State<_DesktopCropDialog> createState() => _DesktopCropDialogState();
}
class _DesktopCropDialogState extends State<_DesktopCropDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  bool _isImageLoaded = false;
  ui.Image? _decodedImage;
  final TransformationController _controller = TransformationController();
  double _minScale = 0.01;

  @override
  void initState() { super.initState(); _decodeAndInitializeImage(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _decodeAndInitializeImage() async {
    final FileImage provider = FileImage(File(widget.imagePath));
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) { setState(() { _decodedImage = info.image; _setupInitialMatrix(); _isImageLoaded = true; }); }
      stream.removeListener(listener!);
    }, onError: (e, s) { stream.removeListener(listener!); });
    stream.addListener(listener);
  }

  void _setupInitialMatrix() {
    if (_decodedImage == null) return;
    const double boxSize = 260.0;
    final double imgWidth = _decodedImage!.width.toDouble();
    final double imgHeight = _decodedImage!.height.toDouble();
    final double coverScale = math.max(boxSize / imgWidth, boxSize / imgHeight);
    _minScale = coverScale;
    _controller.value = Matrix4.identity()
      ..multiply(Matrix4.translationValues((boxSize - imgWidth * coverScale) / 2, (boxSize - imgHeight * coverScale) / 2, 0))
      ..multiply(Matrix4.diagonal3Values(coverScale, coverScale, 1));
  }

  Future<void> _saveCroppedImage() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/desktop_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) { if (mounted) Navigator.pop(context, null); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;
    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480, padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('调整头像', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 32),
            Container(
              width: 260, height: 260, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: theme.textColor.withValues(alpha: 0.1))),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: theme.backgroundColor,
                  child: !_isImageLoaded ? const Center(child: CircularProgressIndicator()) : InteractiveViewer(
                    transformationController: _controller, constrained: false, minScale: _minScale, maxScale: math.max(2.0, _minScale * 5), boundaryMargin: EdgeInsets.zero, child: RawImage(image: _decodedImage),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 16),
                FilledButton(onPressed: _isSaving ? null : _saveCroppedImage, child: const Text('保存头像', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            )
          ],
        ),
      ),
    );
  }
}