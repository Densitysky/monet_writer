import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:monet_writer/services/database_service.dart'; // 【已解封导入】
import 'package:monet_writer/providers/user_provider.dart';

class DesktopDataManagePanel extends StatefulWidget {
  final bool isFlat;
  final WritingTheme currentTheme;
  final Color primaryColor;

  const DesktopDataManagePanel({
    super.key,
    required this.isFlat,
    required this.currentTheme,
    required this.primaryColor
  });

  @override
  State<DesktopDataManagePanel> createState() => _DesktopDataManagePanelState();
}

class _DesktopDataManagePanelState extends State<DesktopDataManagePanel> {
  bool _isProcessing = false;

  // ==================== 1. 导出备份逻辑 ====================
  Future<void> _handleExportBackup() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存备份的位置',
        // 【修改】：后缀名改为 .zip
        fileName: 'MonetWriter_Backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        // 【修改】：允许的后缀改为 zip
        allowedExtensions: ['zip', 'bak'],
      );

      if (outputFile == null) return;

      setState(() => _isProcessing = true);

      // 【实装改动】：调用最新的 Zip 引擎
      await DatabaseService().exportAllDataToZip(outputFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 完美！全库数据已成功打包备份。')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 导出失败: $e', style: const TextStyle(color: Colors.redAccent))));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==================== 2. 导入恢复逻辑 ====================
  Future<void> _handleImportBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择要恢复的备份文件',
        type: FileType.custom,
        // 【修改】：允许的后缀改为 zip
        allowedExtensions: ['zip', 'bak'],
      );

      if (result == null || result.files.isEmpty) return;
      final String filePath = result.files.single.path!;

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.currentTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 16.0)),
          title: Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text('高危操作确认', style: TextStyle(color: widget.currentTheme.textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            '从备份恢复将【彻底清空并覆盖】当前软件内的所有小说、设定和统计数据，且不可逆转！\n\n请确认你选择的备份文件是最新的。',
            style: TextStyle(color: widget.currentTheme.textColor.withValues(alpha: 0.8), height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认覆盖恢复', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isProcessing = true);

      // 【实装改动】：调用最新的 Zip 恢复引擎
      await DatabaseService().importDataFromZip(filePath);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: widget.currentTheme.backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 16.0)),
            title: Text('✅ 涅槃重生', style: TextStyle(color: widget.currentTheme.textColor, fontWeight: FontWeight.bold)),
            content: Text('数据已成功恢复！为了确保界面状态绝对安全，请您手动关闭并重新启动应用程序。', style: TextStyle(color: widget.currentTheme.textColor.withValues(alpha: 0.8))),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('我知道了')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 恢复失败，备份文件可能已损坏: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==================== 3. 批量导出 TXT 逻辑 ====================
  Future<void> _handleExportTxt() async {
    try {
      String? outputDir = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择纯文本导出目录');
      if (outputDir == null) return;

      setState(() => _isProcessing = true);

      // 【实装】：调用底层循环生成全书文本逻辑！
      await DatabaseService().exportAllBooksToTxt(outputDir);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 已成功将所有书籍打包导出至：$outputDir')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ TXT导出失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    final color = isDanger ? Colors.redAccent : widget.primaryColor;
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 12.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 12.0),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDanger ? color : widget.currentTheme.textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: widget.currentTheme.textColor.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton('导出全库备份 (ZIP)', '将所有作品、章节、设定及图片资源打包为备份文件', CupertinoIcons.cloud_download, _handleExportBackup),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton('从备份恢复', '选择之前导出的ZIP备份文件，彻底覆盖当前应用数据', CupertinoIcons.cloud_upload, _handleImportBackup, isDanger: true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton('批量导出纯文本 (TXT)', '将当前所有小说导出为易于分享和上传的 TXT 格式', CupertinoIcons.doc_text, _handleExportTxt),
                ),
                const SizedBox(width: 16),
                const Spacer(), // 留出空位保持网格比例对称
              ],
            )
          ],
        ),

        // 遮罩层与加载动画
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: widget.currentTheme.backgroundColor.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(color: widget.primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}