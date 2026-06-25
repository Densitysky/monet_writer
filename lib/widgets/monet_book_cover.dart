import 'dart:io';
import 'package:flutter/material.dart';
import 'package:monet_writer/models/book/book.dart'; // 【新增】引入 Book 模型
import 'package:monet_writer/utils/color_generator.dart';

class MonetBookCover extends StatelessWidget {
  // 【新增】接收 Book 对象
  final Book? book;

  // 原有参数改为可选，保持向后兼容
  final String? coverPath;
  final String? title;

  final double width;
  final double height;
  final String? heroTag;
  final double radius;
  final BoxShadow? shadow;

  const MonetBookCover({
    super.key,
    this.book,      // 【新增】
    this.coverPath, // 改为可选
    this.title,     // 改为可选
    this.width = 60,
    this.height = 90,
    this.heroTag,
    this.radius = 6,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    // 【核心逻辑】优先使用 book 对象的数据，如果没有则使用单独传入的参数
    final String effectiveTitle = book?.title ?? title ?? '无标题';
    final String? effectiveCoverPath = book?.coverPath ?? coverPath;

    // 1. 基础容器
    Widget coverContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorGenerator.generateBgColor(effectiveTitle), // 动态背景
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          shadow ?? BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageOrPlaceholder(effectiveCoverPath, effectiveTitle),
    );

    // 2. 如果配置了 Hero 动画
    if (heroTag != null) {
      return Hero(tag: heroTag!, child: coverContent);
    }

    return coverContent;
  }

  Widget _buildImageOrPlaceholder(String? path, String displayTitle) {
    final hasImage = path != null && File(path).existsSync();

    if (hasImage) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(displayTitle),
      );
    }
    return _buildPlaceholder(displayTitle);
  }

  Widget _buildPlaceholder(String displayTitle) {
    final bgColor = ColorGenerator.generateBgColor(displayTitle);
    final textColor = ColorGenerator.getTextColor(bgColor);

    // 字体大小根据宽度自适应
    final fontSize = width * 0.4;

    return Center(
      child: Text(
        displayTitle.isNotEmpty ? displayTitle[0] : '无',
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
