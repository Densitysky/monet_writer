import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/models/book/chapter.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/utils/epub_builder.dart'; // 【引入 EpubBuilder】

class ExportService {

  // 1. TXT 导出逻辑 (保持不变)
  static Future<void> exportToTxt(BuildContext context, Book book) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成 TXT 文件...'), duration: Duration(milliseconds: 1000)),
      );

      final isar = DatabaseService().isar;
      final chapters = await isar.chapters
          .filter()
          .bookIdEqualTo(book.id)
          .sortByOrderIndex()
          .findAll();

      if (chapters.isEmpty) {
        _showError(context, '这本书还没有章节');
        return;
      }

      final StringBuffer buffer = StringBuffer();
      buffer.writeln("《${book.title}》");
      buffer.writeln("作者：${book.authorName ?? '佚名'}");
      buffer.writeln("\n${"=" * 20}\n");

      for (var chapter in chapters) {
        buffer.writeln(chapter.title);
        buffer.writeln("-" * 20);
        buffer.writeln(chapter.content);
        buffer.writeln("\n\n");
      }

      await _saveFileToDisk(context, book.title, 'txt', buffer.toString().codeUnits);

    } catch (e) {
      _showError(context, 'TXT 导出失败: $e');
    }
  }

  // 2. 【新增】EPUB 导出逻辑
  static Future<void> exportToEpub(BuildContext context, Book book) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成 EPUB 电子书...'), duration: Duration(seconds: 2)),
      );

      // 1. 获取章节数据
      final isar = DatabaseService().isar;
      final chapters = await isar.chapters
          .filter()
          .bookIdEqualTo(book.id)
          .sortByOrderIndex()
          .findAll();

      if (chapters.isEmpty) {
        _showError(context, '这本书还没有章节');
        return;
      }

      // 2. 调用 EpubBuilder 生成二进制数据
      final epubBytes = EpubBuilder.build(book, chapters);

      // 3. 保存文件
      if (context.mounted) {
        await _saveFileToDisk(context, book.title, 'epub', epubBytes);
      }

    } catch (e) {
      _showError(context, 'EPUB 导出失败: $e');
      debugPrint(e.toString());
    }
  }

  // --- 通用保存逻辑 (复用) ---
  static Future<void> _saveFileToDisk(BuildContext context, String title, String ext, List<int> bytes) async {
    // 1. 写入临时文件
    final directory = await getTemporaryDirectory();
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = "$safeTitle.$ext";
    final tempFile = File('${directory.path}/$fileName');

    await tempFile.writeAsBytes(bytes);

    if (!context.mounted) return;

    // 2. 调起系统保存
    final params = SaveFileDialogParams(
      sourceFilePath: tempFile.path,
      fileName: fileName,
    );

    final filePath = await FlutterFileDialog.saveFile(params: params);

    if (context.mounted && filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $ext 导出成功！'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  static void _showError(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }
}
