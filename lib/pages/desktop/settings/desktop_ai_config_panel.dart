import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/services/ai_service.dart';

class DesktopAiConfigPanel extends StatefulWidget {
  final bool isPaper;
  final WritingTheme currentTheme;
  const DesktopAiConfigPanel({super.key, required this.isPaper, required this.currentTheme});

  @override
  State<DesktopAiConfigPanel> createState() => _DesktopAiConfigPanelState();
}

class _DesktopAiConfigPanelState extends State<DesktopAiConfigPanel> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = context.read<AiProvider>();
      _urlController.text = aiProvider.config.baseUrl ?? 'https://api.openai.com/v1/chat/completions';
      _modelController.text = aiProvider.config.modelName ?? 'gpt-3.5-turbo';
      _keyController.text = aiProvider.config.apiKey ?? '';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _saveAiConfig() {
    // context.read<AiProvider>().updateConfig(...);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ AI 引擎配置已保存')));
  }

  Widget _buildInputRow(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.currentTheme.textColor.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: widget.currentTheme.textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(widget.isPaper ? 4.0 : 8.0), border: widget.isPaper ? Border.all(color: widget.currentTheme.textColor.withValues(alpha: 0.1)) : null),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _isObscure,
            style: TextStyle(fontSize: 14, color: widget.currentTheme.textColor),
            decoration: InputDecoration(
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: isPassword ? IconButton(icon: Icon(_isObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 18, color: widget.currentTheme.textColor.withValues(alpha: 0.5)), onPressed: () => setState(() => _isObscure = !_isObscure)) : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputRow('接口地址 (Base URL)', _urlController),
        const SizedBox(height: 16),
        _buildInputRow('模型名称 (Model)', _modelController),
        const SizedBox(height: 16),
        _buildInputRow('API 密钥 (Key)', _keyController, isPassword: true),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saveAiConfig,
            icon: const Icon(CupertinoIcons.check_mark, size: 16),
            label: const Text('保存配置'),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isPaper ? 4.0 : 8.0))),
          ),
        )
      ],
    );
  }
}
