import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/models/chapter.dart';
import 'package:monet_writer/models/custom_outline.dart';
import 'package:monet_writer/models/character.dart';
import 'package:monet_writer/models/character_group.dart';
import 'package:monet_writer/models/outline_tab.dart';
import 'package:monet_writer/models/outline_node.dart';
import 'package:monet_writer/models/ai_config.dart';
import 'package:monet_writer/models/character_event.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/services/ai_service.dart';
import 'package:monet_writer/services/prompt_manager.dart';
import 'package:monet_writer/models/chapter_history.dart';
import 'package:monet_writer/models/trashed_chapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 【核心新增】：引入排版引擎控制器
import 'package:monet_writer/widgets/editor/monet_editor_controller.dart';

part 'writing/writing_editor_mixin.dart';
part 'writing/writing_chapter_mixin.dart';
part 'writing/writing_character_mixin.dart';
part 'writing/writing_outline_mixin.dart';
part 'writing/writing_history_mixin.dart';
part 'writing/writing_search_mixin.dart';
part 'writing/writing_trash_mixin.dart';
part 'writing/writing_export_mixin.dart';
part 'writing/writing_ai_extraction_mixin.dart';

abstract class WritingProviderBase extends ChangeNotifier {
  final Isar _isar = DatabaseService().isar;
  final Book book;

  Chapter? currentChapter;
  bool isDirty = false;
  bool isSaving = false;

  bool _isAiUpdating = false;
  TextSelection? cachedAiSelection;
  bool isTypewriterMode = false;

  List<String> recentSymbols = ['“', '”', '「', '」', '……', '——', '！', '？', '，', '。'];
  String _lastText = "";
  Timer? _debounceTimer;
  Set<String> _cachedCharacterNames = {};
  final Set<String> _analyzingCharacters = {};

  final TextEditingController titleController = TextEditingController();

  // 【核心修改】：替换为新引擎控制器，并添加焦点管理
  late final MonetEditorController contentController;
  final FocusNode editorFocusNode = FocusNode();

  final UndoHistoryController undoController = UndoHistoryController();
  final ScrollController scrollController = ScrollController();

  WritingProviderBase({required this.book}) {
    contentController = MonetEditorController(); // 实例化新引擎
  }

  @override
  void dispose() {
    scrollController.dispose();
    contentController.dispose();
    editorFocusNode.dispose();
    titleController.dispose();
    undoController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateBook(void Function(Book freshBook) updateAction) async {
    final freshBook = await _isar.books.get(book.id);
    if (freshBook != null) {
      updateAction(freshBook);
      freshBook.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.books.put(freshBook);
      });
      book.description = freshBook.description;
      book.outline = freshBook.outline;
      book.customOutlines = freshBook.customOutlines;
      book.settingsTabs = freshBook.settingsTabs;
      book.characters = freshBook.characters;
      book.characterGroups = freshBook.characterGroups;
      notifyListeners();
    }
  }

  // --- 抽象通道 ---
  void _handleTextChanges();
  void _detectManualSymbolInput();
  Future<void> _initAsync();
  Future<void> saveCurrentChapter();
  void onContentChanged();
  void _refreshNameCache();
  void insertSymbol(String symbol, int offset);
  Future<void> selectChapter(Chapter chapter);
  Future<void> createChapter(String title);
  Future<String> getRecentContent({int limit = 5});

  Future<void> batchAddCharacters(List<dynamic> charList);
}

class WritingProvider extends WritingProviderBase
    with
        WritingEditorMixin,
        WritingChapterMixin,
        WritingCharacterMixin,
        WritingOutlineMixin,
        WritingHistoryMixin,
        WritingSearchMixin,
        WritingTrashMixin,
        WritingExportMixin,
        WritingAiExtractionMixin {

  WritingProvider({required super.book}) {
    contentController.addListener(_handleTextChanges);
    _initAsync().then((_) {
      startHistoryTimer();
    });
  }

  @override
  void dispose() {
    contentController.removeListener(_handleTextChanges);
    stopHistoryTimer();
    super.dispose();
  }
}