import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/models/outline/outline_tab.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/pages/desktop/writing/components/desktop_outline_dialog.dart';
import 'package:monet_writer/pages/desktop/writing/components/desktop_ai_task_manager.dart';

class InspectorOutlineTab extends StatefulWidget {
  final WritingTheme currentTheme;
  final bool isFlat;
  final Color primaryColor;

  const InspectorOutlineTab({
    super.key,
    required this.currentTheme,
    required this.isFlat,
    required this.primaryColor,
  });

  @override
  State<InspectorOutlineTab> createState() => _InspectorOutlineTabState();
}

class _InspectorOutlineTabState extends State<InspectorOutlineTab> {

  Future<void> _handleExtractOutline(BuildContext context, WritingProvider provider) async {
    final aiProvider = context.read<AiProvider>();
    if (aiProvider.config.apiKey.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在全局设置中配置 AI API Key')));
      return;
    }

    if (DesktopAiTaskManager.instance.isWorking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ 已有 AI 任务在后台运行中')));
      return;
    }

    DesktopAiTaskManager.instance.startTask('✨ AI 正在后台分析大纲...');

    try {
      final content = await provider.getRecentContent(limit: 5);
      if (content.isEmpty) throw Exception('当前章节没有正文内容，AI 无法提取。');

      const systemPrompt = '''
你是一个专业的小说助手。请根据用户提供的正文，提取并梳理出本段落的详细剧情大纲。
按剧情发展顺序，列出关键事件、人物动机、冲突和转折。直接输出大纲文本即可，不要任何多余的客套话。
''';
      final userPrompt = "正文片段：\n$content";

      final response = await AiService.generateText(
          aiProvider.config,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt
      );

      final chapterName = provider.currentChapter?.title ?? '当前章节';
      await provider.addPlotNode('✨ $chapterName (AI提炼细纲)', response.trim());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 大纲提取成功，已存入剧情节点')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提取失败: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    } finally {
      DesktopAiTaskManager.instance.stopTask();
    }
  }

  // 【核心修复：为弹窗注入 WritingProvider】
  void _openCoreSettings(BuildContext context, WritingProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ChangeNotifierProvider<WritingProvider>.value(
        value: provider,
        child: DesktopOutlineDialog(
          nodeType: OutlineNodeType.core,
          isEdit: true,
          initialDescription: provider.book.description,
          initialOutline: provider.book.outline,
        ),
      ),
    );
  }

  // 【核心修复：为弹窗注入 WritingProvider】
  void _openPlotNodeDialog(BuildContext context, WritingProvider provider, {required bool isEdit, int? targetIndex, String? title, String? content}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ChangeNotifierProvider<WritingProvider>.value(
        value: provider,
        child: DesktopOutlineDialog(
          nodeType: OutlineNodeType.plotNode,
          isEdit: isEdit,
          targetIndex: targetIndex,
          initialTitle: title,
          initialContent: content,
        ),
      ),
    );
  }

  // 【核心修复：为弹窗注入 WritingProvider】
  void _openTabNodeDialog(BuildContext context, WritingProvider provider, {required bool isEdit, required int tabIndex, int? targetIndex, String? title, String? content}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ChangeNotifierProvider<WritingProvider>.value(
        value: provider,
        child: DesktopOutlineDialog(
          nodeType: OutlineNodeType.tabNode,
          isEdit: isEdit,
          tabIndex: tabIndex,
          targetIndex: targetIndex,
          initialTitle: title,
          initialContent: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingProvider>();
    final customOutlines = provider.book.customOutlines?.toList() ?? [];
    final settingsTabs = provider.book.settingsTabs?.toList() ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: DesktopAiTaskManager.instance,
            builder: (context, _) {
              final isExtracting = DesktopAiTaskManager.instance.isWorking;
              return FilledButton.tonalIcon(
                onPressed: isExtracting ? null : () => _handleExtractOutline(context, provider),
                icon: isExtracting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(CupertinoIcons.wand_rays, size: 14),
                label: Text(isExtracting ? 'AI 后台运行中...' : 'AI 提取本章大纲', style: const TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0)),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSectionHeader('全书设定'),
              _buildClickableCard(
                title: '核心设定与世界观',
                subtitle: provider.book.description?.isNotEmpty == true ? provider.book.description! : '点击完善核心梗概与世界观',
                icon: CupertinoIcons.globe,
                onTap: () => _openCoreSettings(context, provider),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('主线剧情大纲'),
                  IconButton(
                    onPressed: () => _openPlotNodeDialog(context, provider, isEdit: false),
                    icon: Icon(CupertinoIcons.add_circled, size: 16, color: widget.primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (customOutlines.isEmpty)
                Text('暂无剧情节点，点击右上角 + 添加', style: TextStyle(fontSize: 12, color: widget.currentTheme.textColor.withValues(alpha: 0.4))),
              ...List.generate(customOutlines.length, (index) {
                final node = customOutlines[index];
                return _buildClickableCard(
                  title: node.title ?? '未命名节点',
                  subtitle: node.content?.isNotEmpty == true ? node.content! : '暂无详细内容',
                  icon: CupertinoIcons.doc_plaintext,
                  onTap: () => _openPlotNodeDialog(context, provider, isEdit: true, targetIndex: index, title: node.title, content: node.content),
                );
              }),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('分卷与自定义分类'),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请在手机端新建自定义 Tab 分组'))),
                    icon: Icon(CupertinoIcons.folder_badge_plus, size: 16, color: widget.primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (settingsTabs.isEmpty)
                Text('暂无扩展分类', style: TextStyle(fontSize: 12, color: widget.currentTheme.textColor.withValues(alpha: 0.4))),
              ...List.generate(settingsTabs.length, (tabIndex) {
                final tab = settingsTabs[tabIndex];
                return _buildDraggableTabGroup(context, provider, tab, tabIndex);
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.currentTheme.textColor.withValues(alpha: 0.5))),
    );
  }

  Widget _buildClickableCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isFlat ? Colors.transparent : widget.currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0),
        border: Border.all(color: widget.currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, size: 18, color: widget.primaryColor.withValues(alpha: 0.8)),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.currentTheme.textColor)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: widget.currentTheme.textColor.withValues(alpha: 0.5))),
        trailing: Icon(CupertinoIcons.right_chevron, size: 12, color: widget.currentTheme.textColor.withValues(alpha: 0.3)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDraggableTabGroup(BuildContext context, WritingProvider provider, OutlineTab tab, int tabIndex) {
    final nodes = tab.nodes?.toList() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.currentTheme.textColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(widget.isFlat ? 4.0 : 8.0),
        border: Border.all(color: widget.currentTheme.textColor.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(CupertinoIcons.folder, size: 18, color: widget.currentTheme.textColor.withValues(alpha: 0.7)),
          title: Text(tab.title ?? '未命名分组', style: TextStyle(color: widget.currentTheme.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
          iconColor: widget.currentTheme.textColor,
          collapsedIconColor: widget.currentTheme.textColor.withValues(alpha: 0.5),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          children: [
            if (nodes.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nodes.length,
                onReorder: (oldIndex, newIndex) {
                  provider.reorderNodesInTab(tabIndex, oldIndex, newIndex);
                },
                itemBuilder: (context, nodeIndex) {
                  final node = nodes[nodeIndex];
                  return Container(
                    key: ValueKey('${tabIndex}_${nodeIndex}_${node.title}'),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(color: widget.currentTheme.backgroundColor, borderRadius: BorderRadius.circular(4)),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(node.title ?? '未命名', maxLines: 1, style: TextStyle(fontSize: 12, color: widget.currentTheme.textColor)),
                      trailing: const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                      onTap: () => _openTabNodeDialog(context, provider, isEdit: true, tabIndex: tabIndex, targetIndex: nodeIndex, title: node.title, content: node.content),
                    ),
                  );
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openTabNodeDialog(context, provider, isEdit: false, tabIndex: tabIndex),
                icon: Icon(CupertinoIcons.add, size: 12, color: widget.primaryColor),
                label: Text('新增节点', style: TextStyle(fontSize: 12, color: widget.primaryColor)),
              ),
            )
          ],
        ),
      ),
    );
  }
}