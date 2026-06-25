import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/pages/settings_page.dart';
import 'package:monet_writer/pages/image_preview_page.dart';
import 'package:monet_writer/pages/recycle_bin/recycle_bin_page.dart';
import 'package:monet_writer/pages/stats/stats_page.dart';
import 'package:monet_writer/pages/stats/calendar_page.dart';

import 'package:monet_writer/utils/monet_animations.dart';

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
                  }
              ),
              _GridItem(
                  icon: Icons.calendar_month,
                  label: '码字日历',
                  onTap: () {
                    Navigator.push(context, MonetPageRoute(builder: (_) => const CalendarPage()));
                  }
              ),
              _GridItem(
                  icon: Icons.delete_outline,
                  label: '回收站',
                  onTap: () {
                    Navigator.push(context, MonetPageRoute(builder: (_) => const RecycleBinPage()));
                  }
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  String _formatNumber(int count) {
    if (count < 10000) return count.toString();
    return '${(count / 10000).toStringAsFixed(1)}万';
  }

  void _showChangeCoverSheet(BuildContext context, UserProvider userProvider, bool isFlat) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 24.0)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFlat)
                Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
                    ]
                ),
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
                  _pickAndCropCoverImage(context, userProvider);
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

  Future<void> _pickAndCropCoverImage(BuildContext context, UserProvider provider) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(toolbarTitle: '裁切封面', toolbarColor: Colors.black, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.ratio16x9, lockAspectRatio: true),
            IOSUiSettings(title: '裁切封面', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
          ],
        );

        if (croppedFile != null) {
          final directory = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final savedFile = await File(croppedFile.path).copy('${directory.path}/cover_$timestamp.jpg');
          provider.setProfileCoverPath(savedFile.path);
        }
      }
    } catch (e) {
      debugPrint("封面设置失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;

    Widget backgroundLayer;
    final String? bgPath = user.profileCoverPath ?? user.avatarPath;

    if (bgPath != null) {
      backgroundLayer = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(bgPath), fit: BoxFit.cover),
          if (user.isBackgroundBlurred)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            )
          else
            Container(color: Colors.black.withValues(alpha: 0.4)),
        ],
      );
    } else {
      final color = theme.colorScheme.primary;
      backgroundLayer = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.6)],
          ),
        ),
      );
    }

    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isFlat ? 0.0 : 30.0),
          bottomRight: Radius.circular(isFlat ? 0.0 : 30.0),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showChangeCoverSheet(context, user, isFlat),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            backgroundLayer,
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MonetPageRoute(builder: (_) => const SettingsPage()));
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MonetPageRoute(builder: (_) => const ImagePreviewPage()));
                          },
                          child: Hero(
                            tag: 'user_avatar',
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isFlat ? 8.0 : 100.0)
                              ),
                              child: Container(
                                width: 84, height: 84,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(isFlat ? 6.0 : 100.0)
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showEditNicknameDialog(context, user, isFlat),
                                    child: const Icon(Icons.edit_square, size: 18, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(isFlat ? 2.0 : 12.0),
                                ),
                                child: const Text(
                                  'Lv.1 筑基期',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(value: user.consecutiveDays.toString(), label: '连续创作(天)'),
                          const SizedBox(height: 20, child: VerticalDivider(color: Colors.white24)),
                          _StatItem(value: _formatNumber(user.totalWords), label: '累计字数'),
                          const SizedBox(height: 20, child: VerticalDivider(color: Colors.white24)),
                          _StatItem(value: user.todayWords.toString(), label: '今日码字'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, UserProvider user, bool isFlat) {
    final controller = TextEditingController(text: user.nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('修改昵称'),
        content: TextField(controller: controller, maxLength: 12, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
              onPressed: () {
                if(controller.text.isNotEmpty) {
                  user.updateNickname(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存')
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.9,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        // 【已修改】彻底移除了多余的 Border 和底色，回归纯净的扁平留白
        child: Column(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}