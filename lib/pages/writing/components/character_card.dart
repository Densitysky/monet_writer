import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:monet_writer/models/character.dart';

class CharacterCard extends StatefulWidget {
  final Character character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  Color? _extractedColor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant CharacterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果头像路径变了，重新提取颜色
    if (oldWidget.character.avatarPath != widget.character.avatarPath) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    final path = widget.character.avatarPath;
    if (path == null || !File(path).existsSync()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        FileImage(File(path)),
        size: const Size(100, 100), // 小图采样，速度极快
      );

      if (mounted) {
        setState(() {
          // 优先取深色鲜艳色 (Dominant / Vibrant)
          _extractedColor = generator.dominantColor?.color ?? generator.vibrantColor?.color;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.surfaceContainerLow;

    // 如果提取到了颜色，使用它；否则使用默认色
    final accentColor = _extractedColor ?? theme.colorScheme.primary;
    // 背景色：如果是提取的颜色，给 12% 透明度；否则用默认灰色
    final backgroundColor = _extractedColor != null
        ? _extractedColor!.withValues(alpha: 0.12)
        : defaultColor;

    // 头像组件
    Widget avatar;
    if (widget.character.avatarPath != null && File(widget.character.avatarPath!).existsSync()) {
      avatar = CircleAvatar(
        backgroundImage: FileImage(File(widget.character.avatarPath!)),
        backgroundColor: Colors.transparent,
      );
    } else {
      avatar = CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          widget.character.name?.isNotEmpty == true ? widget.character.name![0] : '无',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
      // 这里的颜色设为透明，因为我们在 Container 里控制
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // 确保子组件裁剪圆角
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          // 可选：左侧加一条色带，增强辨识度
          border: Border(
            left: BorderSide(
              color: _extractedColor != null ? accentColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: avatar,
          title: Text(
            widget.character.name ?? '无名氏',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            widget.character.description ?? '暂无简介',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // 如果背景色太深，可能需要调整文字颜色，但 0.12 透明度通常是安全的
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: accentColor.withValues(alpha: 0.7)),
            onSelected: (v) {
              if (v == 'edit') widget.onEdit();
              if (v == 'delete') widget.onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('编辑')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
            ],
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
