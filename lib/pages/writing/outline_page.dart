import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/models/chapter.dart';
import 'package:monet_writer/models/custom_outline.dart'; // 引入自定义大纲模型
import 'package:monet_writer/services/database_service.dart';

class OutlinePage extends StatefulWidget {
  final Book book;
  final Chapter? currentChapter;
  final int initialTabIndex; // 0:全书, 1:分卷, 2:本章, 3+:自定义

  const OutlinePage({
    super.key,
    required this.book,
    this.currentChapter,
    this.initialTabIndex = 0,
  });

  @override
  State<OutlinePage> createState() => _OutlinePageState();
}

class _OutlinePageState extends State<OutlinePage> with TickerProviderStateMixin { // 改为 TickerProviderStateMixin 以支持动态 Tab
  TabController? _tabController;
  final Isar _isar = DatabaseService().isar;

  // --- 固定控制器 ---
  final TextEditingController _bookOutlineCtrl = TextEditingController();
  final TextEditingController _volumeOutlineCtrl = TextEditingController();
  final TextEditingController _chapterOutlineCtrl = TextEditingController();

  // --- 动态控制器 ---
  final List<TextEditingController> _customControllers = [];

  // 防抖 Timer
  Timer? _debounceTimer;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final customOutlines = widget.book.customOutlines ?? [];

    // 1. 初始化控制器数据
    _bookOutlineCtrl.text = widget.book.outline ?? '';
    _volumeOutlineCtrl.text = widget.book.volumeOutline ?? '';
    if (widget.currentChapter != null) {
      _chapterOutlineCtrl.text = widget.currentChapter!.outline ?? '';
    }

    // 2. 初始化自定义大纲控制器
    for (var outline in customOutlines) {
      _customControllers.add(TextEditingController(text: outline.content ?? ''));
    }

    // 3. 初始化 TabController
    // 长度 = 3个固定 (全书/分卷/本章) + 自定义数量
    _tabController = TabController(
      length: 3 + customOutlines.length,
      vsync: this,
      initialIndex: widget.initialTabIndex < (3 + customOutlines.length) ? widget.initialTabIndex : 0,
    );
  }

  @override
  void dispose() {
    _saveData(); // 退出前强制保存
    _debounceTimer?.cancel();
    _tabController?.dispose();
    _bookOutlineCtrl.dispose();
    _volumeOutlineCtrl.dispose();
    _chapterOutlineCtrl.dispose();
    for (var ctrl in _customControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// 保存逻辑
  Future<void> _saveData() async {
    if (!_isDirty) return;

    final bookOutline = _bookOutlineCtrl.text;
    final volumeOutline = _volumeOutlineCtrl.text;
    final chapterOutline = _chapterOutlineCtrl.text;

    await _isar.writeTxn(() async {
      // 1. 保存书的大纲 (固定 + 自定义)
      final freshBook = await _isar.books.get(widget.book.id);
      if (freshBook != null) {
        freshBook.outline = bookOutline;
        freshBook.volumeOutline = volumeOutline;

        // 保存自定义大纲内容
        if (freshBook.customOutlines != null) {
          // 这里使用 List.generate 重新构建列表，确保 Isar 能检测到变更
          // 注意：MVP 版本假设列表顺序未变。更严谨的做法是对比 ID。
          List<CustomOutline> updates = freshBook.customOutlines!.toList();
          for (int i = 0; i < updates.length && i < _customControllers.length; i++) {
            updates[i].content = _customControllers[i].text;
          }
          freshBook.customOutlines = updates;
        }

        await _isar.books.put(freshBook);
      }

      // 2. 保存章节细纲
      if (widget.currentChapter != null) {
        final freshChapter = await _isar.chapters.get(widget.currentChapter!.id);
        if (freshChapter != null) {
          freshChapter.outline = chapterOutline;
          await _isar.chapters.put(freshChapter);
        }
      }
    });

    if (mounted) setState(() => _isDirty = false);
  }

  void _onTextChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), _saveData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customOutlines = widget.book.customOutlines ?? [];

    // 动态构建 Tabs
    List<Tab> tabs = [
      const Tab(text: '全书大纲'),
      const Tab(text: '分卷大纲'),
      const Tab(text: '本章细纲'),
      ...customOutlines.map((e) => Tab(text: e.title ?? '自定义')),
    ];

    // 动态构建 Views
    List<Widget> views = [
      _buildEditor(_bookOutlineCtrl, '记录本书的主线剧情、核心设定...'),
      _buildEditor(_volumeOutlineCtrl, '记录当前卷的冲突、高潮点...'),
      widget.currentChapter == null
          ? const Center(child: Text('请先选择一个章节'))
          : _buildEditor(_chapterOutlineCtrl, '记录本章的剧情细纲，方便写作对照...'),
      ..._customControllers.map((ctrl) => _buildEditor(ctrl, '在此编辑自定义大纲内容...')),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('大纲梳理', style: TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // 【关键】允许横向滚动，防止 Tab 太多挤在一起
          tabAlignment: TabAlignment.start, // 靠左对齐
          tabs: tabs,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _isDirty
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, size: 16, color: Colors.green),
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: views,
      ),
    );
  }

  Widget _buildEditor(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 16, height: 1.6),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
        onChanged: (_) => _onTextChanged(),
      ),
    );
  }
}
