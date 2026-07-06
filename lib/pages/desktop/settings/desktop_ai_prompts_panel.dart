import 'package:flutter/cupertino.dart';
import 'package:monet_writer/providers/user_provider.dart';

class DesktopAiPromptsPanel extends StatelessWidget {
  final bool isPaper;
  final WritingTheme currentTheme;
  final Color primaryColor;

  const DesktopAiPromptsPanel({super.key, required this.isPaper, required this.currentTheme, required this.primaryColor});

  Widget _buildPromptCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor,
        borderRadius: BorderRadius.circular(isPaper ? 4.0 : 8.0),
        border: Border.all(color: currentTheme.textColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              Icon(CupertinoIcons.pencil, size: 16, color: primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, color: currentTheme.textColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPromptCard('原位润色', '进行文学性润色，保留原意，提升辞藻的华丽度。'),
        _buildPromptCard('扩写描写', '扩写细节描写，增加环境渲染、人物心理活动和动作细节。'),
        _buildPromptCard('精简缩写', '精简多余废话，让节奏更加紧凑，动作戏更加凌厉。'),
        _buildPromptCard('智能提取角色', '提取以下正文片段中出场的所有角色，并生成设定 JSON。'),
      ],
    );
  }
}
