import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/services/backup_service.dart';
import 'package:monet_writer/providers/user_provider.dart';

class DataManagePage extends StatefulWidget {
  const DataManagePage({super.key});

  @override
  State<DataManagePage> createState() => _DataManagePageState();
}

class _DataManagePageState extends State<DataManagePage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 顶部提示卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请定期备份您的数据。备份文件包含所有书籍、章节、设定及图片资源。',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 备份按钮
              _buildActionCard(
                context,
                title: '全量备份 (导出)',
                subtitle: '生成 .zip 格式的备份文件，支持分享或保存到本地。',
                icon: Icons.upload_file,
                color: Colors.blue,
                onTap: _handleBackup,
              ),

              const SizedBox(height: 16),

              // 恢复按钮
              _buildActionCard(
                context,
                title: '数据恢复 (导入)',
                subtitle: '从备份文件恢复数据。警告：这将覆盖当前的全部数据！',
                icon: Icons.settings_backup_restore,
                color: Colors.red, // 红色警示
                onTap: _handleRestore,
              ),
            ],
          ),

          // Loading 遮罩
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('正在处理数据...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 处理备份
  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    // 稍微延迟一下让 Loading 显示出来
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      await BackupService().createBackup(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 处理恢复
  Future<void> _handleRestore() async {
    // 1. 弹出警告确认框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 确认恢复数据？'),
        content: const Text(
          '此操作将【彻底清空】当前 App 内的所有书籍和设置，并替换为备份文件中的内容。\n\n该操作不可撤销！',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定覆盖'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      // 2. 调用恢复服务
      final success = await BackupService().restoreBackup(context);

      if (success) {
        // 3. 恢复成功后，必须刷新内存中的状态
        if (mounted) {
          await context.read<UserProvider>().loadUserData(); // 刷新头像、设置
          await context.read<UserProvider>().refreshStats(); // 刷新统计

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 数据恢复成功！'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // 可选：返回上一页或重启 App
          // Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
