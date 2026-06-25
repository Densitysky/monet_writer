import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:monet_writer/services/database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// 1. 创建全量备份 (手机端调用系统分享)
  Future<void> createBackup(BuildContext context) async {
    try {
      // 获取临时目录用于存放即将生成的 zip 包
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/MonetWriter_Backup_${DateTime.now().millisecondsSinceEpoch}.zip';

      // 【核心重构】：直接调用底层强大的、统一的 Zip 打包引擎！
      // 它会自动打包所有的 Isar 数据库表、全局设置(SharedPreferences)以及封面、头像等真实物理图片。
      await DatabaseService().exportAllDataToZip(zipPath);

      // 调起手机系统的分享面板（保存到文件、发送到微信/QQ等）
      final xFile = XFile(zipPath);
      await SharePlus.instance.share(ShareParams(files: [xFile], text: '落笔全量数据备份'));

    } catch (e) {
      debugPrint('Backup failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e')));
      }
      rethrow;
    }
  }

  /// 2. 恢复备份
  Future<bool> restoreBackup(BuildContext context) async {
    try {
      // --- A. 选择文件 ---
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'bak'], // 匹配电脑端，允许选择 zip 后缀
      );

      if (result == null || result.files.single.path == null) return false;

      final String filePath = result.files.single.path!;

      // --- B. 核心重构：调用底层统一的沙盒重写恢复引擎！ ---
      // 引擎会自动解压、将图片安置到真实的沙盒目录，并智能重写数据库和设置里的绝对路径。
      await DatabaseService().importDataFromZip(filePath);

      return true;

    } catch (e) {
      debugPrint('Restore failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
      return false;
    }
  }
}