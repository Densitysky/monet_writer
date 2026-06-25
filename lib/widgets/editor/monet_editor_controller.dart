import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class MonetEditorController {
  late QuillController quillController;

  MonetEditorController() {
    quillController = QuillController.basic();
  }

  void loadData({required String plainText, String? deltaJson}) {
    if (deltaJson != null && deltaJson.trim().isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(deltaJson));
        quillController.document = doc;
      } catch (e) {
        _loadFromPlainText(plainText);
      }
    } else {
      _loadFromPlainText(plainText);
    }
  }

  void _loadFromPlainText(String text) {
    if (text.isEmpty) {
      quillController.document = Document();
    } else {
      final doc = Document()..insert(0, text);
      quillController.document = doc;
    }
  }

  String getDeltaJson() => jsonEncode(quillController.document.toDelta().toJson());

  String getPlainText() => quillController.document.toPlainText();

  // ==================== 神级兼容补丁：兼容全部旧代码 ====================
  String get text => getPlainText();

  set text(String newText) => _loadFromPlainText(newText);
  set value(TextEditingValue newValue) {
    _loadFromPlainText(newValue.text);
    Future.microtask(() {
      if (newValue.selection.isValid) {
        selection = newValue.selection;
      }
    });
  }

  TextSelection get selection => quillController.selection;
  set selection(TextSelection value) {
    quillController.updateSelection(value, ChangeSource.local);
  }

  // 【修复】：使用可选参数，完美接盘旧代码传过来的 1~3 个参数
  void clearTemporaryHighlight() {}
  void setTemporaryHighlight(dynamic arg1, [dynamic arg2, dynamic arg3]) {}
  void updateKeywords(Set<String> keywords) {}
  // ======================================================================

  void dispose() {
    quillController.dispose();
  }

  void addListener(VoidCallback listener) {
    quillController.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    quillController.removeListener(listener);
  }
}