import 'dart:io';
import 'package:flutter/material.dart';

class MonetAvatar extends StatelessWidget {
  final String? avatarPath;
  final String? name; // 用于无图时显示首字 (可选)
  final double size; // 直径
  final String? heroTag;
  final VoidCallback? onTap;
  final bool showBorder;

  const MonetAvatar({
    super.key,
    this.avatarPath,
    this.name,
    this.size = 40,
    this.heroTag,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = avatarPath != null && File(avatarPath!).existsSync();

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? Colors.transparent : theme.colorScheme.surfaceContainerHighest,
        border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
        image: hasImage
            ? DecorationImage(
          image: FileImage(File(avatarPath!)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      alignment: Alignment.center,
      child: !hasImage
          ? (name != null && name!.isNotEmpty
          ? Text(name![0], style: TextStyle(fontSize: size * 0.4, color: theme.colorScheme.onSurfaceVariant))
          : Icon(Icons.person, size: size * 0.6, color: Colors.grey))
          : null,
    );

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
