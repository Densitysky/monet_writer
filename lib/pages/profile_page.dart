import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/utils/monet_animations.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/pages/settings_page.dart';
import 'package:monet_writer/pages/image_preview_page.dart';
import 'package:monet_writer/pages/recycle_bin/recycle_bin_page.dart';
import 'package:monet_writer/pages/stats/stats_page.dart';
import 'package:monet_writer/pages/stats/calendar_page.dart';
import 'package:monet_writer/widgets/theme/app_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().refreshStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GridItem(
                icon: Icons.bar_chart,
                label: '数据统计',
                onTap: () {
                  Navigator.push(context, MonetPageRoute(builder: (_) => const StatsPage()));
                },
              ),
              _GridItem(
                icon: Icons.calendar_month,
                label: '码字日历',
                onTap: () {
                  Navigator.push(context, MonetPageRoute(builder: (_) => const CalendarPage()));
                },
              ),
              _GridItem(
                icon: Icons.delete_outline,
                label: '回收站',
                onTap: () {
                  Navigator.push(context, MonetPageRoute(builder: (_) => const RecycleBinPage()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==================== Profile Header（长按浮动拖拽） ====================

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> with TickerProviderStateMixin {
  static const double _minHeight = 380;
  static const double _snapThreshold = 30;
  static const double _overDragMax = 40;
  static const double _overDragDamping = 0.35;

  late double _maxHeight;
  late double _midHeight;
  double _currentHeight = _minHeight;
  double _startHeight = _minHeight;
  bool _isFloating = false;
  bool _heightLoaded = false;
  bool _heightsInitialized = false;
  bool _wasOverBounds = false;

  late AnimationController _floatAnim;
  late AnimationController _snapAnim;
  double _snapStart = 0;
  double _snapTarget = 0;

  static const String _storageKey = 'profile_header_height';

  @override
  void initState() {
    super.initState();
    _floatAnim = AnimationController(vsync: this, duration: MonetDurations.component);
    _floatAnim.addListener(() => setState(() {}));
    _snapAnim = AnimationController(vsync: this);
    _snapAnim.addListener(() {
      final t = Curves.easeOutCubic.transform(_snapAnim.value);
      setState(() => _currentHeight = _snapStart + (_snapTarget - _snapStart) * t);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _floatAnim.duration = Duration.zero;
      _snapAnim.duration = Duration.zero;
    }
    if (!_heightsInitialized) {
      _initHeights();
      _heightsInitialized = true;
    }
  }

  void _initHeights() {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final topPad = media.padding.top;
    final bottomPad = media.padding.bottom + 56; // nav bar + safe
    const contentBelow = 24.0 + 100.0 + 16.0; // spacing + gridRow + bottomPadding
    _maxHeight = (screenH - topPad - bottomPad - contentBelow).clamp(_minHeight, 900);
    _midHeight = (_minHeight + _maxHeight) / 2;
  }

  Future<void> _loadSavedHeight() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_storageKey);
    if (saved != null && saved >= _minHeight && saved <= _maxHeight) {
      _currentHeight = saved;
    } else {
      _currentHeight = _minHeight;
    }
    setState(() => _heightLoaded = true);
  }

  Future<void> _saveHeight(double h) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storageKey, h);
  }

  // ---- 浮动拖拽 ----

  void _onFloatStart(LongPressStartDetails d) {
    HapticFeedback.mediumImpact();
    _startHeight = _currentHeight;
    _isFloating = true;
    _floatAnim.forward();
  }

  void _onFloatMove(LongPressMoveUpdateDetails d) {
    if (!_isFloating) return;
    final rawH = _startHeight + d.offsetFromOrigin.dy;
    double h;
    if (rawH > _maxHeight) {
      // 往下超出：橡皮筋
      final overshoot = rawH - _maxHeight;
      h = _maxHeight + (overshoot * _overDragDamping).clamp(0.0, _overDragMax);
      if (!_wasOverBounds) { _wasOverBounds = true; HapticFeedback.lightImpact(); }
    } else {
      // 正常范围 + 往上最小 380 硬限制
      h = rawH.clamp(_minHeight, _maxHeight);
      _wasOverBounds = false;
    }
    if ((h - _currentHeight).abs() > 1) {
      setState(() => _currentHeight = h);
    }
  }

  void _onFloatEnd(LongPressEndDetails d) {
    _snapAndExit();
  }

  void _onFloatUp() {
    _snapAndExit();
  }

  void _snapAndExit() {
    final isOverShot = _currentHeight > _maxHeight || _currentHeight < _minHeight;
    double target;

    if (isOverShot) {
      // 弹回边界，延长动画到 400ms
      _snapAnim.duration = MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.page;
      target = _currentHeight.clamp(_minHeight, _maxHeight);
    } else {
      // 找最近磁吸点
      _snapAnim.duration = MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.component;
      double nearest = _minHeight;
      double minDist = (_currentHeight - _minHeight).abs();
      for (final pt in [_minHeight, _midHeight, _maxHeight]) {
        final dist = (_currentHeight - pt).abs();
        if (dist < minDist) { minDist = dist; nearest = pt; }
      }
      target = minDist <= _snapThreshold ? nearest : _currentHeight;
    }

    _snapStart = _currentHeight;
    _snapTarget = target;
    _isFloating = false;
    _wasOverBounds = false;
    _floatAnim.reverse();
    _snapAnim.reset();
    _snapAnim.forward();
    _saveHeight(target);
  }

  // ---- 封面更换 ----

  void _showChangeCoverSheet(UserProvider userProvider, bool isPaper) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(isPaper ? 0.0 : 24.0)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPaper)
                const Column(children: [
                  SizedBox(height: 12),
                  _HandleBar(),
                ]),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('更换主页封面', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (userProvider.avatarPath != null)
                ListTile(
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  title: const Text('同步使用当前头像'),
                  onTap: () {
                    Navigator.pop(ctx);
                    userProvider.setProfileCoverPath(userProvider.avatarPath);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已同步头像为封面')));
                  },
                ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: const Text('从相册选择新图片...'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndCropCoverImage(userProvider);
                },
              ),
              if (userProvider.profileCoverPath != null)
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                  title: const Text('移除当前封面', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    userProvider.setProfileCoverPath(null);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndCropCoverImage(UserProvider provider) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 390.0, ratioY: _maxHeight),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪高版封面',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.teal,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: '裁剪高版封面', aspectRatioLockEnabled: true),
        ],
      );
      if (croppedFile == null || !mounted) return;

      CroppedFile? shortFile = await ImageCropper().cropImage(
        sourcePath: croppedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 390.0, ratioY: _minHeight),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪矮版封面',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.teal,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: '裁剪矮版封面', aspectRatioLockEnabled: true),
        ],
      );
      if (shortFile == null || !mounted) return;

      // 保存高版（长板），用 topCenter 对齐：矮时显示顶部，高时展示完整
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = await File(croppedFile.path).copy('${directory.path}/cover_$timestamp.jpg');
      provider.setProfileCoverPath(savedFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('封面已更新')),
        );
      }
    } catch (e) {
      debugPrint("封面设置失败: $e");
    }
  }

  void _showEditNicknameDialog(UserProvider user, bool isPaper) {
    final controller = TextEditingController(text: user.nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0)),
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          maxLength: 12,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 12.0))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0))),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                user.updateNickname(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int count) {
    if (count < 10000) return count.toString();
    return '${(count / 10000).toStringAsFixed(1)}万';
  }

  @override
  void dispose() {
    _floatAnim.dispose();
    _snapAnim.dispose();
    super.dispose();
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final isPaper = context.watch<ThemeProvider>().isPaperOrParchment;
    final isNeumorphic = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.neumorphic;  //柔和模式

    if (!_heightsInitialized) {
      return const SizedBox(height: _minHeight);
    }
    if (!_heightLoaded) {
      _loadSavedHeight();
      return const SizedBox(height: _minHeight);
    }

    final t = _floatAnim.value;
    final h = _currentHeight;

    // 背景层 — 顶部固定对齐，拖拽时底部自然裁剪
    final String? bgPath = user.profileCoverPath ?? user.avatarPath;
    final primary = theme.colorScheme.primary;
    // 自动计算背景上的文字对比色（深色背景→白字，浅色背景→黑字）
    final textColor = primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    Widget backgroundLayer;
    if (bgPath != null) {
      backgroundLayer = Image.file(
        File(bgPath),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: h,
      );
    } else {
      // 纯色背景替代渐变
      backgroundLayer = Container(color: primary);
    }

    return Padding(
      padding: isNeumorphic ? const EdgeInsets.fromLTRB(12, 12, 12, 0) : EdgeInsets.zero,
      child: AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        // 浮动态：加阴影 + 上浮
        return Container(
          decoration: BoxDecoration(
            // 柔和模式：四周圆角卡片；其他模式：仅底部圆角
            borderRadius: isNeumorphic
                ? BorderRadius.circular(24)
                : BorderRadius.only(
                    bottomLeft: Radius.circular(isPaper ? 0.0 : 30.0),
                    bottomRight: Radius.circular(isPaper ? 0.0 : 30.0),
                  ),
            boxShadow: t > 0.01
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25 * t),
                      blurRadius: 16 * t,
                      offset: Offset(0, 6 * t),
                    ),
                  ]
                : isNeumorphic
                    ? const [
                        // 柔和模式：完整新拟态双阴影，让头部浮在背景上
                        BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
                        BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(4, 4), blurRadius: 18),
                      ]
                    : null,
          ),
          child: Transform.translate(
            offset: Offset(0, -4 * t),
            child: child,
          ),
        );
      },
      child: Container(
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isPaper ? 0.0 : 30.0),
            bottomRight: Radius.circular(isPaper ? 0.0 : 30.0),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景层 — 长按/点击手势只在此区域生效
            GestureDetector(
              onTap: () => _showChangeCoverSheet(user, isPaper),
              onLongPressStart: _onFloatStart,
              onLongPressMoveUpdate: _onFloatMove,
              onLongPressEnd: _onFloatEnd,
              onLongPressUp: _onFloatUp,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  backgroundLayer,
                  // 浮动态遮罩
                  if (_isFloating)
                    Positioned.fill(
                      child: Container(color: textColor.withValues(alpha: 0.08)),
                    ),
                ],
              ),
            ),

            // 设置按钮 — 固定在右上角
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: textColor.withValues(alpha: _isFloating ? 0.4 : 1.0)),
                    onPressed: _isFloating ? null : () {
                      Navigator.push(context, MonetPageRoute(builder: (_) => const SettingsPage()));
                    },
                  ),
                ),
              ),
            ),

            // 内容区 — 不拦截手势，ListView 可正常滚动
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),
                      // 头像 + 昵称 + 等级
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _isFloating ? null : () {
                              Navigator.push(context, MonetPageRoute(builder: (_) => const ImagePreviewPage()));
                            },
                            child: Hero(
                              tag: 'user_avatar',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isPaper ? 8.0 : 100.0),
                                  // 浅色背景时白圈需要灰色描边，否则和背景融为一体
                                  border: (isNeumorphic && textColor == Colors.black)
                                      ? Border.all(color: Colors.grey.shade300, width: 1)
                                      : null,
                                  // 新拟态浮雕
                                  boxShadow: isNeumorphic
                                      ? const [
                                          BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-3, -3), blurRadius: 6),
                                          BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(3, 3), blurRadius: 10),
                                        ]
                                      : null,
                                ),
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(isPaper ? 6.0 : 100.0),
                                  ),
                                  child: user.avatarPath != null
                                      ? Image.file(File(user.avatarPath!), fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.nickname,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _isFloating ? null : () => _showEditNicknameDialog(user, isPaper),
                                      child: Icon(Icons.edit_square, size: 18, color: textColor.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(isPaper ? 2.0 : 12.0),
                                  ),
                                  child: Text(
                                    'Lv.1 筑基期',
                                    style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 统计行
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(value: user.consecutiveDays.toString(), label: '连续创作(天)', color: textColor),
                            SizedBox(height: 20, child: VerticalDivider(color: textColor.withValues(alpha: 0.15))),
                            _StatItem(value: _formatNumber(user.totalWords), label: '累计字数', color: textColor),
                            SizedBox(height: 20, child: VerticalDivider(color: textColor.withValues(alpha: 0.15))),
                            _StatItem(value: user.todayWords.toString(), label: '今日码字', color: textColor),
                          ],
                        ),
                      ),

                      // 浮动拖拽指示条
                      AnimatedOpacity(
                        opacity: _isFloating ? 1.0 : 0.0,
                        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : MonetDurations.quick,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
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
          ],
        ),
      ),
    ),
    );
  }
}

// ==================== 小组件 ====================

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GridItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;

    final content = Column(
      children: [
        Icon(icon, size: 30, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
      ],
    );

    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.9,
      child: isNeumorphic
          ? AppCard(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(width: 100, child: content),
            )
          : Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: content,
            ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  const _HandleBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
    );
  }
}

