part of '../writing_provider.dart';

/// 零件八：排版与导出核心逻辑
mixin WritingExportMixin on WritingProviderBase {

  /// ✨ 核心科技：智能排版并复制到剪贴板
  Future<bool> smartCopyCurrentChapter() async {
    if (currentChapter == null) return false;
    String text = contentController.text;

    // 1. 按换行符分割，正则 `\n+` 会自动过滤掉用户多敲的所有空行
    final paragraphs = text.split(RegExp(r'\n+'));

    // 2. 遍历每一段，去除首尾乱按的空格，并强制加上网文标准的“全角双空格”缩进
    final formatted = paragraphs.map((p) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) return '';
      return '　　$trimmed'; // 前面是两个全角空格
    }).where((p) => p.isNotEmpty).join('\n'); // 段落间以单换行紧密拼接

    // 3. 瞬间写入手机剪贴板
    await Clipboard.setData(ClipboardData(text: formatted));
    return true;
  }

  /// 📄 原汁原味无损复制
  Future<bool> rawCopyCurrentChapter() async {
    if (currentChapter == null) return false;
    await Clipboard.setData(ClipboardData(text: contentController.text));
    return true;
  }

  /// 💾 导出本章 TXT 并呼出系统分享
  Future<bool> exportCurrentChapterTxt() async {
    if (currentChapter == null) return false;
    try {
      final dir = await getTemporaryDirectory();
      // 在缓存目录生成临时的 TXT 文件
      final file = File('${dir.path}/${currentChapter!.title}.txt');
      await file.writeAsString(contentController.text);

      // 呼出原生分享面板（微信、QQ、保存到文件等）
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '分享章节：${currentChapter!.title}'));
      return true;
    } catch (e) {
      debugPrint('导出失败: $e');
      return false;
    }
  }

  /// 📚 导出全书合并 TXT (自动拼接所有未删除章节)
  Future<bool> exportWholeBookTxt() async {
    try {
      // 抓取全书有效章节
      final chapters = await _isar.chapters.filter().bookIdEqualTo(book.id).sortByOrderIndex().findAll();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/《${book.title}》全本导出.txt');

      final buffer = StringBuffer();
      buffer.writeln('《${book.title}》\n');
      buffer.writeln('导出时间：${DateTime.now().toString().substring(0, 16)}\n');
      buffer.writeln('====================\n\n');

      // 循环拼接
      for (var c in chapters) {
        buffer.writeln('【${c.title}】\n');
        buffer.writeln('${c.content}\n');
        buffer.writeln('--------------------\n');
      }

      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '分享全书：《${book.title}》'));
      return true;
    } catch (e) {
      debugPrint('全书导出失败: $e');
      return false;
    }
  }
}