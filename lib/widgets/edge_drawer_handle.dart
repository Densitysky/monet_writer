import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 屏幕边缘抽屉手柄
///
/// 替换原先不可见的双击热区，提供可见的视觉提示，
/// 点击即可打开抽屉，同时保留拖拽拉出能力。
class EdgeDrawerHandle extends StatefulWidget {
  /// 手柄位于左侧还是右侧
  final bool isLeft;

  /// 打开抽屉的回调
  final VoidCallback onOpen;

  /// 手柄颜色（建议用当前主题文字色的低透明度版本）
  final Color color;

  /// 是否已关闭抽屉拖拽手势（由外部 Scaffold 控制）
  final bool drawerDragEnabled;

  const EdgeDrawerHandle({
    super.key,
    required this.isLeft,
    required this.onOpen,
    required this.color,
    this.drawerDragEnabled = true,
  });

  @override
  State<EdgeDrawerHandle> createState() => _EdgeDrawerHandleState();
}

class _EdgeDrawerHandleState extends State<EdgeDrawerHandle>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    final handleColor = _isHovering
        ? widget.color.withValues(alpha: 0.6)
        : widget.color.withValues(alpha: 0.18);

    return Positioned(
      left: widget.isLeft ? 0 : null,
      right: widget.isLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          child: SizedBox(
            width: 48,
            child: Stack(
              children: [
                // 指示线（可见标记）
                Positioned(
                  left: widget.isLeft ? 0 : null,
                  right: widget.isLeft ? null : 0,
                  top: MediaQuery.of(context).size.height * 0.3,
                  bottom: MediaQuery.of(context).size.height * 0.2,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _isHovering
                            ? handleColor
                            : widget.color.withValues(alpha: _pulseAnimation.value),
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(2),
                          bottom: const Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
