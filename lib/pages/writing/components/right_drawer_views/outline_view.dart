import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/models/outline/custom_outline.dart';
import 'package:monet_writer/models/outline/outline_tab.dart';
import 'package:monet_writer/services/ai_service.dart';

import 'package:monet_writer/utils/markdown_text_editing_controller.dart';
import 'package:monet_writer/pages/writing/components/markdown_toolbar.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class OutlineView extends StatefulWidget {
  final bool isFullScreen;

  const OutlineView({super.key, this.isFullScreen = false});

  @override
  State<OutlineView> createState() => _OutlineViewState();
}

class _OutlineViewState extends State<OutlineView> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  int _selectedMacroIndex = 0;

  final _descCtrl = MarkdownTextEditingController();
  final _outlineCtrl = MarkdownTextEditingController();
  final _customTextCtrl = MarkdownTextEditingController();

  bool _isDirty = false;
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) _saveAll();
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;
    final book = context.read<WritingProvider>().book;
    _descCtrl.text = book.description ?? '';
    _outlineCtrl.text = book.outline ?? '';
    _loadCustomTabContent();
  }

  void _loadCustomTabContent() {
    final provider = context.read<WritingProvider>();
    final tabs = provider.book.settingsTabs ?? [];
    if (_selectedMacroIndex > 0 && (_selectedMacroIndex - 1) < tabs.length) {
      final tab = tabs[_selectedMacroIndex - 1];
      if (tab.type == OutlineType.text) {
        _customTextCtrl.text = tab.textContent ?? '';
      }
    }
  }

  @override
  void dispose() {
    _saveAll();
    _mainTabController.dispose();
    _descCtrl.dispose();
    _outlineCtrl.dispose();
    _customTextCtrl.dispose();
    super.dispose();
  }

  void _saveAll() {
    if (!_isDirty) return;
    final provider = context.read<WritingProvider>();

    provider.updateCoreOutline(_descCtrl.text, _outlineCtrl.text);

    final tabs = provider.book.settingsTabs ?? [];
    if (_selectedMacroIndex > 0 && (_selectedMacroIndex - 1) < tabs.length) {
      final tab = tabs[_selectedMacroIndex - 1];
      if (tab.type == OutlineType.text) {
        provider.updateTabContent(_selectedMacroIndex - 1, _customTextCtrl.text);
      }
    }

    setState(() => _isDirty = false);
  }

  Future<void> _handleAiAction() async {
    final aiProvider = context.read<AiProvider>();
    if (aiProvider.config.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在设置中配置 AI API Key')));
      return;
    }

    setState(() => _isAiLoading = true);
    final provider = context.read<WritingProvider>();

    try {
      if (_mainTabController.index == 1) {
        final nodeData = await provider.generatePlotNodeFromContent(aiProvider.config);
        await provider.addPlotNode(nodeData['title']!, nodeData['content']!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 剧情节点已生成并保存'), backgroundColor: Colors.green));
        }
      } else {
        final tabs = provider.book.settingsTabs ?? [];
        bool isTextMode = false;
        TextEditingController? targetCtrl;
        String settingType = "世界观与总纲";

        if (_selectedMacroIndex == 0) {
          isTextMode = true;
          targetCtrl = _outlineCtrl;
          settingType = "小说世界观与核心大纲";
        } else if ((_selectedMacroIndex - 1) < tabs.length) {
          final tab = tabs[_selectedMacroIndex - 1];
          if (tab.type == OutlineType.text) {
            isTextMode = true;
            targetCtrl = _customTextCtrl;
            settingType = tab.title ?? "专属设定";
          }
        }

        if (isTextMode && targetCtrl != null) {
          final currentText = targetCtrl.text;
          final newText = await provider.expandSettingWithAi(aiProvider.config, settingType, currentText);

          if (newText.isNotEmpty) {
            targetCtrl.text = currentText.isEmpty ? newText : "$currentText\n\n【AI 补全】\n$newText";
            _isDirty = true;
            _saveAll();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 设定已自动补全并安全存档'), backgroundColor: Colors.green));
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('列表型设定集暂不支持自动生成')));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  void _toggleFullScreen() {
    if (widget.isFullScreen) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        MonetPageRoute(builder: (_) => const Scaffold(
          body: SafeArea(child: OutlineView(isFullScreen: true)),
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WritingProvider>();
    final currentTheme = context.watch<UserProvider>().currentTheme;

    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.transparent,
            child: Row(
              children: [
                if (widget.isFullScreen)
                  IconButton(icon: Icon(Icons.arrow_back, color: currentTheme.textColor), onPressed: () => Navigator.pop(context)),

                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentTheme.textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0),
                    ),
                    child: TabBar(
                      controller: _mainTabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0),
                      ),
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: currentTheme.textColor.withValues(alpha: 0.6),
                      dividerColor: Colors.transparent,
                      tabs: const [Tab(text: '宏观 · 设定'), Tab(text: '剧情 · 细纲')],
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(widget.isFullScreen ? Icons.close_fullscreen : Icons.open_in_full, color: currentTheme.textColor.withValues(alpha: 0.7)),
                  tooltip: widget.isFullScreen ? '退出全屏' : '全屏编辑',
                  onPressed: _toggleFullScreen,
                )
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildMacroPage(context, provider, theme, currentTheme, isFlat),
                _buildPlotPage(context, provider, theme, currentTheme, isFlat),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isAiLoading
          ? FloatingActionButton.small(
        onPressed: null,
        backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
        shape: isFlat ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)) : null,
        child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      )
          : FloatingActionButton.small(
        onPressed: _handleAiAction,
        tooltip: 'AI 自动生成/补全',
        backgroundColor: theme.colorScheme.primaryContainer,
        shape: isFlat ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)) : null,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildMacroPage(BuildContext context, WritingProvider provider, ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    final tabs = provider.book.settingsTabs ?? [];

    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: currentTheme.textColor.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: currentTheme.textColor),
                onPressed: () => _showAllTabsMenu(context, provider, tabs, isFlat),
                tooltip: '查看所有设定',
              ),
              VerticalDivider(width: 1, indent: 10, endIndent: 10, color: currentTheme.textColor.withValues(alpha: 0.1)),

              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _buildChip(0, '核心', Icons.dashboard, theme, currentTheme, isFlat),
                    ...List.generate(tabs.length, (index) {
                      final tab = tabs[index];
                      return GestureDetector(
                        onLongPress: () => _showTabMenu(context, provider, index, tab, isFlat),
                        child: _buildChip(
                            index + 1,
                            tab.title ?? '未命名',
                            tab.type == OutlineType.text ? Icons.description : Icons.list_alt,
                            theme,
                            currentTheme,
                            isFlat
                        ),
                      );
                    }),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => _showCreateTabDialog(context, provider, isFlat),
                        style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0))
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _selectedMacroIndex == 0
              ? _buildCoreView(theme, currentTheme, isFlat)
              : _buildCustomTabView(provider, tabs, theme, currentTheme, isFlat),
        ),
      ],
    );
  }

  void _showAllTabsMenu(BuildContext context, WritingProvider provider, List<OutlineTab> tabs, bool isFlat) {
    showModalBottomSheet(
      context: context,
      showDragHandle: !isFlat,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 24.0))),
      builder: (ctx) => SizedBox(
        height: 300,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("切换设定集", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildGridItem(ctx, 0, '核心', Icons.dashboard, Colors.blue, isFlat, currentTheme: context.read<UserProvider>().currentTheme),
                  ...List.generate(tabs.length, (i) {
                    final tab = tabs[i];
                    return _buildGridItem(
                        ctx, i + 1, tab.title ?? '',
                        tab.type == OutlineType.text ? Icons.description : Icons.list_alt,
                        Colors.indigo,
                        isFlat,
                        currentTheme: context.read<UserProvider>().currentTheme
                    );
                  })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext ctx, int index, String label, IconData icon, Color color, bool isFlat, {required WritingTheme currentTheme}) {
    final isSelected = _selectedMacroIndex == index;
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        _saveAll();
        setState(() {
          _selectedMacroIndex = index;
          _loadCustomTabContent();
        });
      },
      borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : currentTheme.textColor.withValues(alpha: 0.05), // 【彻底删除边框】改用底色区分层级
          borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 4),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? color : Colors.black87))),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(int index, String label, IconData icon, ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    final isSelected = _selectedMacroIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
        selectedColor: theme.colorScheme.primaryContainer,
        avatar: Icon(icon, size: 16, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
        label: Text(label, style: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : currentTheme.textColor)),
        onSelected: (_) {
          _saveAll();
          setState(() {
            _selectedMacroIndex = index;
            _loadCustomTabContent();
          });
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0),
            side: BorderSide.none // 【彻底删除边框】
        ),
      ),
    );
  }

  Widget _buildCoreView(ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('核心梗概 (Logline)', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        MarkdownToolbar(controller: _descCtrl),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          style: TextStyle(color: currentTheme.textColor),
          decoration: _inputDeco(theme, currentTheme, '一句话讲清楚：谁？要干什么？阻碍是什么？', isFlat),
          onChanged: (_) => _isDirty = true,
        ),
        const SizedBox(height: 24),
        Text('世界观与总纲', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        MarkdownToolbar(controller: _outlineCtrl),
        TextField(
          controller: _outlineCtrl,
          maxLines: null,
          minLines: 10,
          style: TextStyle(color: currentTheme.textColor),
          decoration: _inputDeco(theme, currentTheme, '在此书写完整的故事大纲、结局规划、体系设定...', isFlat),
          onChanged: (_) => _isDirty = true,
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildCustomTabView(WritingProvider provider, List<OutlineTab> tabs, ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    if ((_selectedMacroIndex - 1) >= tabs.length) return const SizedBox();

    final tabIndex = _selectedMacroIndex - 1;
    final tab = tabs[tabIndex];

    if (tab.type == OutlineType.text) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownToolbar(controller: _customTextCtrl),
            Expanded(
              child: TextField(
                controller: _customTextCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 16, height: 1.6, color: currentTheme.textColor),
                decoration: _inputDeco(theme, currentTheme, '在此记录${tab.title}的详细设定...', isFlat),
                onChanged: (_) => _isDirty = true,
              ),
            ),
          ],
        ),
      );
    }

    return _buildNodeList(
      context,
      theme,
      currentTheme,
      isFlat,
      nodes: tab.nodes ?? [],
      onReorder: (oldIdx, newIdx) => provider.reorderNodesInTab(tabIndex, oldIdx, newIdx),
      onAdd: () => _showNodeDialog(context, (t, c) => provider.addNodeToTab(tabIndex, t, c), isFlat),
      onEdit: (node, nodeIdx) => _showNodeDialog(context, (t, c) => provider.updateNodeInTab(tabIndex, nodeIdx, t, c), isFlat, node: node),
      onDelete: (nodeIdx) => provider.deleteNodeInTab(tabIndex, nodeIdx),
    );
  }

  Widget _buildPlotPage(BuildContext context, WritingProvider provider, ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    final nodes = provider.book.customOutlines ?? [];

    return _buildNodeList(
      context,
      theme,
      currentTheme,
      isFlat,
      nodes: nodes,
      isLegacy: true,
      onReorder: provider.reorderPlotNodes,
      onAdd: () => _showNodeDialog(context, provider.addPlotNode, isFlat),
      onEdit: (node, index) => _showNodeDialog(context, (t, c) => provider.updatePlotNode(index, t, c), isFlat, legacyNode: node as CustomOutline),
      onDelete: provider.deletePlotNode,
    );
  }

  InputDecoration _inputDeco(ThemeData theme, WritingTheme currentTheme, String hint, bool isFlat) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)),
      filled: true,
      fillColor: currentTheme.textColor.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildNodeList(
      BuildContext context,
      ThemeData theme,
      WritingTheme currentTheme,
      bool isFlat,
      {
        required List<dynamic> nodes,
        required Function(int, int) onReorder,
        required VoidCallback onAdd,
        required Function(dynamic, int) onEdit,
        required Function(int) onDelete,
        bool isLegacy = false,
      }
      ) {
    if (nodes.isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: onAdd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(2, 60),
                painter: _DashedLinePainter(color: currentTheme.textColor.withValues(alpha: 0.2)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isFlat ? 8.0 : 100.0),
                ),
                child: Icon(Icons.add, size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text('点击添加第一个事件节点', style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              const SizedBox(height: 4),
              Text('开始梳理你的故事脉络', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.5), fontSize: 12)),
              const SizedBox(height: 16),
              CustomPaint(
                size: const Size(2, 60),
                painter: _DashedLinePainter(color: currentTheme.textColor.withValues(alpha: 0.2)),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: nodes.length,
          onReorder: onReorder,
          proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
          itemBuilder: (context, index) {
            final node = nodes[index];
            final title = node.title ?? '未命名';
            final content = node.content ?? '';

            return Container(
              key: ValueKey(node.hashCode),
              margin: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Center(child: Container(width: 2, color: currentTheme.textColor.withValues(alpha: 0.1)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onEdit(node, index),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: currentTheme.textColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0),
                            // 【彻底删除边框】去除大纲节点上的 border
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor))),
                                  InkWell(
                                    onTap: () => onDelete(index),
                                    child: Icon(Icons.close, size: 14, color: currentTheme.textColor.withValues(alpha: 0.4)),
                                  )
                                ],
                              ),
                              if (content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: currentTheme.textColor.withValues(alpha: 0.6))),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton.small(
                heroTag: 'manual_add',
                onPressed: onAdd,
                shape: isFlat ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)) : null,
                child: const Icon(Icons.add)
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateTabDialog(BuildContext context, WritingProvider provider, bool isFlat) {
    final ctrl = TextEditingController();
    OutlineType selectedType = OutlineType.text;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
          title: const Text('新建设定集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(labelText: '名称', hintText: '例如: 魔法体系', border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ChoiceChip(label: const Text('文本模式'), selected: selectedType == OutlineType.text, onSelected: (b) => setState(() => selectedType = OutlineType.text))),
                  const SizedBox(width: 8),
                  Expanded(child: ChoiceChip(label: const Text('列表模式'), selected: selectedType == OutlineType.list, onSelected: (b) => setState(() => selectedType = OutlineType.list))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  provider.createSettingsTab(ctrl.text, selectedType);
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTabMenu(BuildContext context, WritingProvider provider, int index, OutlineTab tab, bool isFlat) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 24.0))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit), title: const Text('重命名'),
            onTap: () { Navigator.pop(ctx); _showRenameTabDialog(context, provider, index, tab.title ?? '', isFlat); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red), title: const Text('删除此设定集', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              provider.deleteSettingsTab(index);
              if (_selectedMacroIndex == (index + 1)) setState(() => _selectedMacroIndex = 0);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameTabDialog(BuildContext context, WritingProvider provider, int index, String oldName, bool isFlat) {
    final ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('重命名'),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
              onPressed: () { if (ctrl.text.isNotEmpty) { provider.renameSettingsTab(index, ctrl.text); Navigator.pop(context); }},
              child: const Text('确定')
          ),
        ],
      ),
    );
  }

  void _showNodeDialog(BuildContext context, Function(String, String) onSave, bool isFlat, {dynamic node, CustomOutline? legacyNode}) {
    final title = node?.title ?? legacyNode?.title ?? '';
    final content = node?.content ?? legacyNode?.content ?? '';
    final tCtrl = TextEditingController(text: title);

    final cCtrl = MarkdownTextEditingController(text: content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: Text(title.isEmpty ? '添加条目' : '编辑条目'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tCtrl, autofocus: true, decoration: InputDecoration(labelText: '标题', border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))),
              const SizedBox(height: 12),
              MarkdownToolbar(controller: cCtrl),
              TextField(controller: cCtrl, maxLines: 5, decoration: InputDecoration(labelText: '内容详情', border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0))),
              onPressed: () { if (tCtrl.text.isNotEmpty) { onSave(tCtrl.text, cCtrl.text); Navigator.pop(context); }},
              child: const Text('保存')
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + 5), paint);
      startY += 10;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}