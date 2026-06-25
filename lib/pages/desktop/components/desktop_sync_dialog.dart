import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/sync_server_service.dart';

class DesktopSyncDialog extends StatefulWidget {
  final bool isFlat;
  const DesktopSyncDialog({super.key, required this.isFlat});

  @override
  State<DesktopSyncDialog> createState() => _DesktopSyncDialogState();
}

class _DesktopSyncDialogState extends State<DesktopSyncDialog> {
  bool _isStarting = true;
  bool _startSuccess = false;

  @override
  void initState() {
    super.initState();
    _initServer();
  }

  Future<void> _initServer() async {
    final success = await SyncServerService().startServer();
    if (mounted) {
      setState(() {
        _isStarting = false;
        _startSuccess = success;
      });
    }
  }

  @override
  void dispose() {
    // 弹窗关闭时，安全销毁局域网服务，防止后台占用端口
    SyncServerService().stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final currentTheme = user.currentTheme;
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 8.0 : 24.0)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.wifi, color: primaryColor),
                    const SizedBox(width: 8),
                    Text('局域网安全同步', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  ],
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.xmark, color: currentTheme.textColor.withValues(alpha: 0.5), size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),

            if (_isStarting)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_startSuccess)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text('启动服务失败，请检查网络或端口是否被占用', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8))),
                ),
              )
            else ...[
                // === 核心区域：二维码展示 ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // 二维码底色必须是白色，确保手机能扫出
                    borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 16.0),
                    border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.1)),
                  ),
                  child: QrImageView(
                    // 【核心修复】：去掉了非法下划线，使用 monetsync://
                    data: 'monetsync://${SyncServerService().ip}:${SyncServerService().port}?pin=${SyncServerService().pin}',
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(color: Colors.black87),
                    dataModuleStyle: const QrDataModuleStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),

                // === 信息与提示区 ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 12.0),
                  ),
                  child: Column(
                    children: [
                      Text('请使用手机端 Monet Writer 的右上角扫码', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.8), fontSize: 13)),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: currentTheme.textColor.withValues(alpha: 0.05)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('设备 IP', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(SyncServerService().ip, style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: currentTheme.textColor.withValues(alpha: 0.1)),
                          Column(
                            children: [
                              Text('安全码 (PIN)', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(SyncServerService().pin, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2.0)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 16),
            Text('⚠️ 提示：请确保手机和电脑连接在同一个 WiFi 路由器下', style: TextStyle(fontSize: 11, color: currentTheme.textColor.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}