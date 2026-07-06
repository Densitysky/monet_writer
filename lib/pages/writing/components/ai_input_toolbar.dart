import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart'; // 【新增】
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】
import 'package:monet_writer/utils/monet_animations.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/models/ai/ai_config.dart';

enum _AiStatus { input, loading, success }

class AiInputToolbar extends StatefulWidget {
  final VoidCallback onClose;

  const AiInputToolbar({
    super.key,
    required this.onClose,
  });

  @override
  State<AiInputToolbar> createState() => _AiInputToolbarState();
}

class _AiInputToolbarState extends State<AiInputToolbar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _AiStatus _status = _AiStatus.input;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<AiConfig> _getConfig() async {
    final db = DatabaseService();
    final configs = await db.getAllAiConfigs();
    if (configs.isEmpty) {
      throw Exception("未找到可用的 AI 配置，请先在设置中添加模型。");
    }
    return configs.first;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _status = _AiStatus.loading);

    try {
      final config = await _getConfig();
      final provider = context.read<WritingProvider>();
      await provider.replaceSelectionWithAi(config, text);

      if (mounted) setState(() => _status = _AiStatus.success);
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) {
        setState(() => _status = _AiStatus.input);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI 请求失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<UserProvider>().currentTheme;
    final isPaper = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.paper;
    const accentColor = Colors.purpleAccent; // 保持魔法紫作为点缀

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor, // 完美融入底色
        border: Border(
          top: BorderSide(color: isPaper ? currentTheme.textColor.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.5), width: 1),
        ),
        boxShadow: [
          if (!isPaper) // 纸感风不要阴影
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: MonetDurations.quick,
          child: _buildContent(currentTheme, isPaper, accentColor),
        ),
      ),
    );
  }

  Widget _buildContent(WritingTheme currentTheme, bool isPaper, Color accentColor) {
    switch (_status) {
      case _AiStatus.loading:
        return _buildStatusRow(
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent)),
          "AI 正在生成中...",
          accentColor,
        );
      case _AiStatus.success:
        return _buildStatusRow(
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          "生成完成",
          Colors.greenAccent,
        );
      case _AiStatus.input:
      default:
        return _buildInputRow(currentTheme, isPaper, accentColor);
    }
  }

  Widget _buildInputRow(WritingTheme currentTheme, bool isPaper, Color accentColor) {
    return Row(
      key: const ValueKey('input'),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(Icons.auto_awesome, color: accentColor, size: 20),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: currentTheme.textColor.withValues(alpha: 0.05), // 高级透明底色
              borderRadius: BorderRadius.circular(isPaper ? 4.0 : 20.0), // 动态圆角
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: currentTheme.textColor),
              decoration: InputDecoration(
                hintText: "告诉 AI 怎么改... (如：扩写这段话)",
                hintStyle: TextStyle(fontSize: 14, color: currentTheme.textColor.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.arrow_upward_rounded, color: accentColor),
          onPressed: _send,
          tooltip: '发送',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        IconButton(
          icon: Icon(Icons.close, color: currentTheme.textColor.withValues(alpha: 0.5)),
          onPressed: widget.onClose,
          tooltip: '取消',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  Widget _buildStatusRow(Widget icon, String text, Color textColor) {
    return Container(
      key: ValueKey(text),
      height: 48,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

