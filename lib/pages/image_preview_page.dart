import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:monet_writer/providers/user_provider.dart';

/// 头像全屏预览页
/// 功能：查看大图、调用 UserProvider 进行头像更换与裁切
class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({super.key});
  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {

  Future<void> _pickAndCropImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    // 1. 裁剪逻辑 (1:1 比例)
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁切头像',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.teal,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: '裁切头像',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (croppedFile != null && context.mounted) {
      // 2. 调用 Provider 更新
      try {
        context.read<UserProvider>().updateAvatarPath(croppedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      } catch (e) {
        debugPrint('Error updating avatar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请检查 UserProvider')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听 UserProvider，以便头像更新后立即刷新显示
    final userProvider = context.watch<UserProvider>();
    final avatarPath = userProvider.avatarPath;

    return Scaffold(
      backgroundColor: Colors.black,
      // 顶部透明导航栏
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 使用 Stack 布局，将按钮悬浮在图片上方
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 图片主体 (居中显示)
          Center(
            child: Hero(
              tag: 'user_avatar', // 保持与 ProfilePage 一致的 tag 实现动画衔接
              child: avatarPath != null
                  ? Image.file(
                File(avatarPath),
                fit: BoxFit.contain, // 保持比例显示完整图片
              )
                  : const Icon(Icons.account_circle,
                  size: 150, color: Colors.grey),
            ),

          ),

          // 2. 底部操作栏
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _pickAndCropImage(context),
                icon: const Icon(Icons.crop_rotate), // 使用裁切图标更直观
                label: const Text('更换并裁切头像'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,

                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
