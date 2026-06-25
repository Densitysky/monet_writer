import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';

class ImageExportPage extends StatefulWidget {
  final WritingProvider provider;
  const ImageExportPage({super.key, required this.provider});

  @override
  State<ImageExportPage> createState() => _ImageExportPageState();
}

class _ImageExportPageState extends State<ImageExportPage> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isGenerating = false;

  /// 核心生成逻辑：将 RepaintBoundary 截取为 PNG 图片并分享
  Future<void> _shareImage() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      // 1. 寻找虚拟相机 (RepaintBoundary)
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 2. 拍下照片 (pixelRatio 控制清晰度，2.0 足以应对文字且防止超长图内存溢出)
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 3. 写入临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/分享长图_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // 4. 呼出系统分享面板
      final title = widget.provider.currentChapter?.title ?? '无标题';
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '分享章节：$title'));

    } catch (e) {
      debugPrint('生成长图失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('长图生成失败，可能文章过长导致内存不足')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = userProvider.currentTheme;
    final provider = widget.provider;

    final chapter = provider.currentChapter;
    final title = chapter?.title ?? '无标题';

    // 对长图文字进行一次简单的智能排版（压缩空行）
    final rawText = provider.contentController.text;
    final paragraphs = rawText.split(RegExp(r'\n+')).where((p) => p.trim().isNotEmpty);
    final formattedText = paragraphs.map((p) => '　　${p.trim()}').join('\n\n');

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 提取背景图片（如果有的话）
    DecorationImage? bgImage;
    if (userProvider.backgroundImagePath != null) {
      final file = File(userProvider.backgroundImagePath!);
      if (file.existsSync()) {
        bgImage = DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
        );
      }
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('预览长图', style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ==================== 预览区域 ====================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                // 增加阴影，让它看起来像一张悬浮的纸
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: _globalKey, // <--- 虚拟照相机的取景框
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        image: bgImage, // 完美继承背景图
                      ),
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // 紧贴内容高度
                        children: [
                          // 顶部：书名与章节名
                          Text(
                            provider.book.title,
                            style: TextStyle(fontSize: 14, color: theme.textColor.withValues(alpha: 0.6), letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textColor, height: 1.3),
                          ),
                          const SizedBox(height: 24),
                          Container(width: 40, height: 2, color: theme.textColor.withValues(alpha: 0.2)),
                          const SizedBox(height: 30),

                          // 中部：经过智能排版的正文
                          Text(
                            formattedText,
                            style: TextStyle(
                              fontSize: userProvider.fontSize,
                              height: userProvider.lineHeight,
                              fontFamily: userProvider.effectiveFontFamily,
                              color: theme.textColor.withValues(alpha: 0.9),
                            ),
                          ),

                          const SizedBox(height: 50),
                          Divider(color: theme.textColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 20),

                          // 底部：版权水印与统计信息
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Monet Writer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor.withValues(alpha: 0.8), letterSpacing: 1)),
                                  const SizedBox(height: 6),
                                  Text('沉浸式写作体验', style: TextStyle(fontSize: 10, color: theme.textColor.withValues(alpha: 0.4))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('共 ${chapter?.wordCount ?? 0} 字', style: TextStyle(fontSize: 12, color: theme.textColor.withValues(alpha: 0.6))),
                                  const SizedBox(height: 4),
                                  Text(dateStr, style: TextStyle(fontSize: 10, color: theme.textColor.withValues(alpha: 0.4))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==================== 底部操作栏 ====================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _shareImage,
                  icon: _isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(CupertinoIcons.share),
                  label: Text(_isGenerating ? '正在渲染长图...' : '分享高清长图', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.textColor.withValues(alpha: 0.8),
                    foregroundColor: theme.backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}