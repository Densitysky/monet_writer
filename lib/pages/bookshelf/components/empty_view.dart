import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final VoidCallback onCreate;

  const EmptyView({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 80, color: theme.colorScheme.surfaceContainerHighest),
          const SizedBox(height: 16),
          Text(
            '还没有书籍',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('创建第一本小说'),
          ),
        ],
      ),
    );
  }
}
