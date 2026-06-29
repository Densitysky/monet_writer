import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// Monet 动效令牌 — 统一缓动曲线与时长体系
// ============================================================
// 三级动效层级：
//   L1 - Micro (150ms)  : 按钮反馈、开关切换、图标变化
//   L2 - Component (300ms): 抽屉展开、卡片展开、下拉菜单、对话框
//   L3 - Page (500ms)      : 路由转场、全屏模态
//
// 原则：
//   - 入场用 easeOut (先快后慢，可感知)
//   - 出场用 easeIn (先慢后快，不拖沓)
//   - 禁止回弹/弹性缓动 (不符合专业写作工具气质)
// ============================================================

class MonetDurations {
  const MonetDurations._();

  static const micro  = Duration(milliseconds: 150);
  static const component = Duration(milliseconds: 300);
  static const page   = Duration(milliseconds: 500);

  /// 快速进场（如 SnackBar、toast）
  static const quick = Duration(milliseconds: 200);
}

class MonetCurves {
  const MonetCurves._();

  /// 入场：先快后慢，视觉感知强
  static const entry = Curves.easeOutExpo;

  /// 出场：先慢后快，不拖泥带水
  static const exit = Curves.easeInQuart;

  /// 微交互按压反馈
  static const press = Curves.easeOutCubic;

  /// 展开/折叠（组件级）
  static const expand = Curves.easeOutQuart;
}

// ============================================================
// L3 — 品牌化页面路由转场
// ============================================================

/// 替换默认 MaterialPageRoute 的带品牌动效路由
///
/// 入场：从右侧 10% 滑入 + 淡入，500ms easeOutExpo
/// 出场：向左滑出 + 淡出，300ms easeInQuart
class MonetPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  MonetPageRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: MonetDurations.page,
          reverseTransitionDuration: MonetDurations.component,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.of(context).disableAnimations) return child;
            final curvedEntry = CurvedAnimation(
              parent: animation,
              curve: MonetCurves.entry,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(curvedEntry),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(curvedEntry),
                child: child,
              ),
            );
          },
        );
}

/// 从底部弹出的品牌路由（类似 iOS modal）
///
/// 入场：从底部 100% 滑入，300ms easeOutExpo
/// 出场：向下滑出，300ms easeInQuart
class MonetModalRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  MonetModalRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: MonetDurations.component,
          reverseTransitionDuration: MonetDurations.component,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.of(context).disableAnimations) return child;
            final curvedEntry = CurvedAnimation(
              parent: animation,
              curve: MonetCurves.entry,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedEntry),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(curvedEntry),
                child: child,
              ),
            );
          },
        );
}

// ============================================================
// L2 — 组件级转场
// ============================================================

/// Fade + 轻微上滑的组件进场
///
/// 从下方 6% 滑入 + 淡入，适合列表项、卡片延迟渲染
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final bool disableSlide;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.disableSlide = false,
  });

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MonetDurations.component,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: MonetCurves.entry),
    );
    _slide = widget.disableSlide
        ? Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller)
        : Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: MonetCurves.entry),
          );

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.duration = Duration.zero;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// 通用缩放+淡入弹窗动画（L2 组件级）
Future<T?> showMonetDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'monet_dialog',
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.component,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: MonetCurves.entry,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

// ============================================================
// L1 — 微交互
// ============================================================

/// 按压弹缩反馈 (L1 Micro)
///
/// 使用 Transform.scale 而非 AnimatedScale（避免 layout thrashing）
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final bool haptic;

  const BouncingWidget({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.94,
    this.haptic = true,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MonetDurations.micro);
    _controller.addListener(() {
      setState(() => _currentScale = 1.0 - (1.0 - widget.scaleFactor) * _controller.value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.duration = Duration.zero;
    }
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  void _onTap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    if (_controller.duration == Duration.zero) { widget.onTap(); return; }
    _controller..value = 0..forward().then((_) => widget.onTap());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Transform.scale(scale: _currentScale, child: widget.child),
    );
  }
}

/// 淡入淡出（L1 Micro）—— 用于状态切换
class CrossFadeToggle extends StatelessWidget {
  final Widget firstChild;
  final Widget secondChild;
  final bool showSecond;

  const CrossFadeToggle({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.showSecond,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState:
          showSecond ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: MonetDurations.micro,
      firstCurve: MonetCurves.entry,
      secondCurve: MonetCurves.entry,
    );
  }
}

// ============================================================
// 兼容旧 API（标记为 deprecated，逐步迁移）
// ============================================================

@Deprecated('Use MonetDurations.component + showMonetDialog instead')
Future<T?> showSpringDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showMonetDialog(context: context, builder: builder);
}
