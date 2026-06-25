part of '../writing_provider.dart';

/// 零件五：时光机（历史快照）核心控制逻辑
mixin WritingHistoryMixin on WritingProviderBase {
  Timer? _historyTimer;
  String _lastSnapshotContent = "";

  // ==================== 定时器生命周期 ====================

  /// 开启历史快照定时器 (10 分钟一次)
  void startHistoryTimer() {
    _historyTimer?.cancel();

    // 初始化时记录一下当前的初始内容，防止刚打开就存一次毫无变化的记录
    _lastSnapshotContent = contentController.text;

    _historyTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      recordSnapshot();
    });
  }

  /// 停止定时器并触发最后一次保存 (用于退出界面时)
  void stopHistoryTimer() {
    _historyTimer?.cancel();
    // 退出界面前，强制执行一次快照记录
    recordSnapshot();
  }

  // ==================== 快照核心业务 ====================

  /// 核心：静默记录快照
  Future<void> recordSnapshot() async {
    if (currentChapter == null) return;

    final currentContent = contentController.text;

    // 【防抖去重机制】如果当前内容和上一次快照完全一样，或者内容为空，则直接跳过！
    // 这能彻底防止用户挂机发呆时，数据库产生大量完全相同的废数据。
    if (currentContent == _lastSnapshotContent || currentContent.trim().isEmpty) {
      return;
    }

    // 计算纯文字字数（复用之前去水的规则）
    final wordCount = currentContent.replaceAll(RegExp(r'\s'), '').length;

    // 调用底层数据库服务保存快照
    await DatabaseService().saveChapterHistory(
      currentChapter!.id,
      currentContent,
      wordCount,
    );

    // 更新内存中的最后快照引用
    _lastSnapshotContent = currentContent;
  }

  /// 核心：恢复历史快照
  Future<void> restoreHistory(ChapterHistory history) async {
    if (currentChapter == null) return;

    // 【后悔药机制】在用历史版本覆盖当前内容前，先自动为“当前界面的内容”打一次快照，防止手滑点错！
    await recordSnapshot();

    // 覆盖文本内容
    contentController.text = history.content;
    _lastSnapshotContent = history.content;

    // 将光标自动移至文本末尾
    contentController.selection = TextSelection.collapsed(offset: history.content.length);

    // 立即触发一次物理保存并通知 UI 刷新
    isDirty = true;
    notifyListeners();
    await saveCurrentChapter();
  }

  // 声明基类提供的抽象方法通道
  @override
  Future<void> saveCurrentChapter();
}