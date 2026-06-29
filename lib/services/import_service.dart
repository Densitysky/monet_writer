import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/models/book/chapter.dart';
import 'package:monet_writer/services/database_service.dart';

class ImportResult {
  final bool success;
  final String message;
  final int bookId;
  final int chapterCount;

  const ImportResult({
    required this.success,
    required this.message,
    this.bookId = -1,
    this.chapterCount = 0,
  });
}

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  final _db = DatabaseService();

  /// 章节标题正则（中文 / 英文）
  static final _chapterPattern = RegExp(
    r'(?:^|\n)\s*(第[零一二三四五六七八九十百千\d]+章[^\n]*|Chapter\s+\d+[^\n]*)\s*\n',
    multiLine: true,
  );

  // ──────────────── 入口 ────────────────

  Future<ImportResult> importFromFile(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    try {
      if (ext == 'txt') {
        return await _importTxt(filePath);
      } else if (ext == 'epub') {
        return await _importEpub(filePath);
      } else {
        return const ImportResult(success: false, message: '不支持的文件格式，请选择 .txt 或 .epub 文件');
      }
    } catch (e) {
      return ImportResult(success: false, message: '导入失败：$e');
    }
  }

  // ──────────────── TXT 导入 ────────────────

  Future<ImportResult> _importTxt(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ImportResult(success: false, message: '文件不存在');
    }

    final rawText = await file.readAsString(encoding: _detectEncoding(await file.readAsBytes()));
    final fileName = filePath.split('/').last.split('\\').last.replaceFirst(RegExp(r'\.txt$', caseSensitive: false), '');

    final chapters = _splitChapters(rawText);

    // 标题推断
    String bookTitle = fileName;
    if (chapters.isNotEmpty && chapters.first.title.isNotEmpty) {
      final firstMatch = _chapterPattern.firstMatch(rawText);
      if (firstMatch != null && firstMatch.start > 0) {
        final prefix = rawText.substring(0, firstMatch.start).trim();
        if (prefix.isNotEmpty && prefix.length < 80) {
          bookTitle = prefix;
        }
      }
    }

    return await _createBook(bookTitle, chapters);
  }

  // ──────────────── EPUB 导入 ────────────────

  Future<ImportResult> _importEpub(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. 找到 container.xml
    final containerFile = archive.findFile('META-INF/container.xml');
    if (containerFile == null) {
      return const ImportResult(success: false, message: '无效的 EPUB 文件：缺少 container.xml');
    }
    final containerXml = XmlDocument.parse(utf8.decode(containerFile.content as List<int>));
    final rootfile = containerXml.findAllElements('rootfile').firstOrNull;
    final opfPath = rootfile?.getAttribute('full-path');
    if (opfPath == null) {
      return const ImportResult(success: false, message: '无效的 EPUB 文件：无法找到 OPF 路径');
    }

    // 2. 解析 OPF
    final opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      return ImportResult(success: false, message: '无效的 EPUB 文件：找不到 $opfPath');
    }
    final opfXml = XmlDocument.parse(utf8.decode(opfFile.content as List<int>));
    final package = opfXml.findAllElements('package').firstOrNull;
    if (package == null) {
      return const ImportResult(success: false, message: '无效的 EPUB 文件：缺少 package 元素');
    }

    // 书名
    final titleElement = package
        .findAllElements('title')
        .firstOrNull;
    final bookTitle = titleElement?.innerText.trim() ?? '未命名书籍';

    // 构建 id => href 映射
    final manifest = package.findAllElements('manifest').firstOrNull;
    final Map<String, String> idToHref = {};
    if (manifest != null) {
      for (final item in manifest.findAllElements('item')) {
        final id = item.getAttribute('id');
        final href = item.getAttribute('href');
        if (id != null && href != null) {
          idToHref[id] = href;
        }
      }
    }

    // 3. 按 spine 顺序提取章节
    final spine = package.findAllElements('spine').firstOrNull;
    final List<ChapterData> chapters = [];
    String? firstXhtmlContent;

    if (spine != null) {
      final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/')) : '';
      for (final itemref in spine.findAllElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref == null) continue;
        final href = idToHref[idref];
        if (href == null) continue;

        final filePath = opfDir.isEmpty ? href : '$opfDir/$href';
        final xhtmlFile = archive.findFile(filePath) ?? archive.findFile(href);
        if (xhtmlFile == null) continue;

        final raw = utf8.decode(xhtmlFile.content as List<int>);
        final doc = XmlDocument.parse(raw);

        // 章节标题
        String chapterTitle = '';
        final titleTags = doc.findAllElements('title');
        if (titleTags.isNotEmpty) {
          chapterTitle = titleTags.first.innerText.trim();
        }
        if (chapterTitle.isEmpty) {
          final h1 = doc.findAllElements('h1').firstOrNull;
          if (h1 != null) chapterTitle = h1.innerText.trim();
        }
        if (chapterTitle.isEmpty) {
          chapterTitle = href.split('/').last.replaceFirst(RegExp(r'\.[^.]+$'), '');
        }

        // 提取正文纯文本
        final body = doc.findAllElements('body').firstOrNull;
        String content = body?.innerText ?? doc.rootElement.innerText;
        content = _cleanHtmlText(content);

        if (firstXhtmlContent == null && content.trim().isEmpty) {
          firstXhtmlContent = '';
          continue; // 跳过封面等空白页
        }

        if (content.trim().isNotEmpty) {
          chapters.add(ChapterData(title: chapterTitle, content: content));
        }
      }
    }

    // 无章节内容回退
    if (chapters.isEmpty) {
      // 尝试直接找所有 XHTML
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.toLowerCase();
        if (!name.endsWith('.xhtml') && !name.endsWith('.html') && !name.endsWith('.htm')) continue;
        final raw = utf8.decode(file.content as List<int>);
        final doc = XmlDocument.parse(raw);
        final body = doc.findAllElements('body').firstOrNull;
        String content = body?.innerText ?? '';
        content = _cleanHtmlText(content);
        if (content.trim().isNotEmpty) {
          chapters.add(ChapterData(title: file.name.split('/').last, content: content));
        }
      }
    }

    if (chapters.isEmpty) {
      return const ImportResult(success: false, message: 'EPUB 文件中未找到可读内容');
    }

    return await _createBook(bookTitle, chapters);
  }

  // ──────────────── 章节分割 ────────────────

  List<ChapterData> _splitChapters(String text) {
    final matches = _chapterPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return [ChapterData(title: '正文', content: text.trim())];
    }

    final List<ChapterData> chapters = [];
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final title = match.group(1)!.trim();
      final start = match.end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final content = text.substring(start, end).trim();
      if (content.isNotEmpty) {
        chapters.add(ChapterData(title: title, content: content));
      }
    }

    return chapters.isEmpty ? [ChapterData(title: '正文', content: text.trim())] : chapters;
  }

  // ──────────────── 数据库写入 ────────────────

  Future<ImportResult> _createBook(String title, List<ChapterData> chapters) async {
    final isar = _db.isar;

    // 创建 Book
    final book = Book()
      ..title = title
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    late int bookId;
    await isar.writeTxn(() async {
      bookId = await isar.books.put(book);
    });

    // 批量创建 Chapter
    int totalWords = 0;
    await isar.writeTxn(() async {
      for (int i = 0; i < chapters.length; i++) {
        final c = chapters[i];
        final wc = c.content.replaceAll(RegExp(r'\s+'), '').length;
        totalWords += wc;
        final chapter = Chapter()
          ..bookId = bookId
          ..title = c.title
          ..content = c.content
          ..wordCount = wc
          ..orderIndex = i
          ..updatedAt = DateTime.now();
        await isar.chapters.put(chapter);

        if (i == 0) {
          // 更新 lastChapterId
          book.lastChapterId = chapter.id;
          await isar.books.put(book);
        }
      }

      // 更新总字数
      book.wordCount = totalWords;
      await isar.books.put(book);
    });

    return ImportResult(
      success: true,
      message: '已导入《$title》，共 ${chapters.length} 章',
      bookId: bookId,
      chapterCount: chapters.length,
    );
  }

  // ──────────────── 工具方法 ────────────────

  /// 编码检测：优先 UTF-8，回退 latin1
  Encoding _detectEncoding(List<int> bytes) {
    try {
      utf8.decode(bytes);
      return utf8;
    } catch (_) {
      return latin1;
    }
  }

  /// 清理 HTML 实体和多余空白
  String _cleanHtmlText(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

/// 解析后的章节数据
class ChapterData {
  final String title;
  final String content;

  const ChapterData({required this.title, required this.content});
}
