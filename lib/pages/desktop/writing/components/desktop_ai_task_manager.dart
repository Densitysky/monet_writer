import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';

/// 桌面专属：AI 全局后台任务管理器 (单例模式，绝不污染安卓端状态)
class DesktopAiTaskManager extends ChangeNotifier {
  static final DesktopAiTaskManager instance = DesktopAiTaskManager._();
  DesktopAiTaskManager._();

  bool _isWorking = false;
  String _statusText = '';

  bool get isWorking => _isWorking;
  String get statusText => _statusText;

  void startTask(String status) {
    _isWorking = true;
    _statusText = status;
    notifyListeners();
  }

  void stopTask() {
    _isWorking = false;
    _statusText = '';
    notifyListeners();
  }
}

/// 桌面专属：悬浮在右下角的全局呼吸灯指示器
class DesktopAiTaskIndicator extends StatelessWidget {
  const DesktopAiTaskIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isFlat = themeProvider.themeStyle == AppThemeStyle.flat;
    final currentTheme = userProvider.currentTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: DesktopAiTaskManager.instance,
      builder: (context, _) {
        final isWorking = DesktopAiTaskManager.instance.isWorking;
        final text = DesktopAiTaskManager.instance.statusText;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          bottom: isWorking ? 24.0 : -80.0, // 隐藏时滑出屏幕下方
          right: 24.0, // 悬浮在右下角
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isWorking ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isFlat ? currentTheme.backgroundColor : currentTheme.textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                boxShadow: isFlat ? null : [
                  BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}