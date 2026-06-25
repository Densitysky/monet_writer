import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'package:monet_writer/providers/user_provider.dart';

/// 全局通用的桌面端图片自由拖拽裁剪弹窗
class DesktopCropDialog extends StatefulWidget {
  final String imagePath;           // 原图路径
  final String title;               // 弹窗标题 (如: '调整头像', '调整封面')
  final double boxWidth;            // 取景框宽度
  final double boxHeight;           // 取景框高度
  final BoxShape shape;             // 取景框形状 (圆形/矩形)
  final BorderRadius? borderRadius; // 圆角 (矩形时生效)

  const DesktopCropDialog({
    super.key,
    required this.imagePath,
    this.title = '调整图片',
    required this.boxWidth,
    required this.boxHeight,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  State<DesktopCropDialog> createState() => _DesktopCropDialogState();
}

class _DesktopCropDialogState extends State<DesktopCropDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;

  bool _isImageLoaded = false;
  ui.Image? _decodedImage;
  final TransformationController _controller = TransformationController();
  double _minScale = 0.01;

  @override
  void initState() {
    super.initState();
    _decodeAndInitializeImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decodeAndInitializeImage() async {
    final FileImage provider = FileImage(File(widget.imagePath));
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;

    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _decodedImage = info.image;
          _setupInitialMatrix();
          _isImageLoaded = true;
        });
      }
      stream.removeListener(listener!);
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      debugPrint('图片解码失败: $exception');
      stream.removeListener(listener!);
    });

    stream.addListener(listener);
  }

  void _setupInitialMatrix() {
    if (_decodedImage == null) return;

    final double imgWidth = _decodedImage!.width.toDouble();
    final double imgHeight = _decodedImage!.height.toDouble();

    // 动态获取外部传入的宽高计算极限缩放比
    final double scaleX = widget.boxWidth / imgWidth;
    final double scaleY = widget.boxHeight / imgHeight;
    final double coverScale = math.max(scaleX, scaleY);

    _minScale = coverScale;

    // 计算居中偏移量
    final double dx = (widget.boxWidth - imgWidth * coverScale) / 2;
    final double dy = (widget.boxHeight - imgHeight * coverScale) / 2;

    _controller.value = Matrix4.identity()
      ..multiply(Matrix4.translationValues(dx, dy, 0))
      ..multiply(Matrix4.diagonal3Values(coverScale, coverScale, 1));
  }

  Future<void> _saveCroppedImage() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final String fileName = 'desktop_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      debugPrint('裁剪保存失败: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<UserProvider>().currentTheme;

    // 弹窗的宽度自动适配取景框的大小
    final double dialogWidth = math.max(480.0, widget.boxWidth + 80.0);

    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 8),
            Text('支持鼠标拖拽平移、滚轮缩放', style: TextStyle(fontSize: 13, color: theme.textColor.withValues(alpha: 0.5))),
            const SizedBox(height: 32),

            // 核心取景框
            Container(
              width: widget.boxWidth,
              height: widget.boxHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.05),
                shape: widget.shape,
                borderRadius: widget.borderRadius,
                border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
              ),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: theme.backgroundColor,
                  child: !_isImageLoaded
                      ? const Center(child: CircularProgressIndicator())
                      : InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    minScale: _minScale,
                    maxScale: math.max(2.0, _minScale * 5),
                    boundaryMargin: EdgeInsets.zero,
                    child: RawImage(image: _decodedImage),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _saveCroppedImage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('确认保存', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}