import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/utils/text_format_util.dart';

/// 一键排版按钮组件 (侧边栏工具箱专属)
class AutoFormatTile extends StatelessWidget {
  const AutoFormatTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.format_align_left, color: theme.colorScheme.primary),
      title: const Text('一键自动排版'),
      trailing: const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
      onTap: () {
        final provider = context.read<WritingProvider>();

        // 【天才的桥接方法】：用一个临时的原生 Controller 喂给旧的排版工具
        // 排版完后再把数据塞回我们的新引擎中！不需要修改你底层的工具代码！
        final tempController = TextEditingController(text: provider.contentController.text);
        tempController.selection = provider.contentController.selection;

        TextFormatUtil.autoFormat(
          tempController,
              () {
            // 将排版后的文本和光标更新回富文本引擎
            provider.contentController.text = tempController.text;
            provider.contentController.selection = tempController.selection;
            provider.onContentChanged(); // 触发脏标记和保存
          },
        );

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 排版完成：已自动缩进并清理多余空行'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}