import 'package:flutter/material.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/models/inspiration_fragment.dart';

/// 灵感碎片数据模型 (纯内存)
class InspirationItem {
  final int? id;
  final String content;
  final String? note;
  final String tag;
  final String? bookTitle;
  final DateTime createTime;
  final DateTime updateTime;

  const InspirationItem({
    this.id,
    required this.content,
    this.note,
    this.tag = '其他',
    this.bookTitle,
    required this.createTime,
    required this.updateTime,
  });
}

class InspirationsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<InspirationItem> _allFragments = [];
  String _activeTag = '全部';
  String _searchQuery = '';

  List<InspirationItem> get allFragments => _allFragments;
  String get activeTag => _activeTag;
  String get searchQuery => _searchQuery;

  static const List<String> availableTags = ['全部','角色','情节','场景','金句','世界观','其他'];

  Future<void> loadFragments() async {
    final results = await _db.getAllInspirationFragments();
    results.sort((a, b) => b.updateTime.compareTo(a.updateTime));
    _allFragments = results.map((f) => InspirationItem(
      id: f.id, content: f.content, note: f.note, tag: f.tag,
      bookTitle: f.bookTitle, createTime: f.createTime, updateTime: f.updateTime,
    )).toList();
    notifyListeners();
  }

  List<InspirationItem> get filteredFragments {
    var list = _allFragments;
    if (_activeTag != '全部') list = list.where((f) => f.tag == _activeTag).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) =>
        f.content.toLowerCase().contains(q) ||
        (f.note?.toLowerCase().contains(q) ?? false) ||
        (f.bookTitle?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  void setActiveTag(String tag) { _activeTag = tag; notifyListeners(); }
  void setSearchQuery(String query) { _searchQuery = query; notifyListeners(); }

  Future<void> addFragment({required String content, String? note, String tag = '其他', String? bookTitle}) async {
    final now = DateTime.now();
    final f = InspirationFragment()
      ..content = content..note = note..tag = tag..bookTitle = bookTitle
      ..createTime = now..updateTime = now;
    await _db.isar.writeTxn(() async { await _db.isar.inspirationFragments.put(f); });
    await loadFragments();
  }

  Future<void> updateFragment({required int id, String? content, String? note, String? tag, String? bookTitle}) async {
    await _db.isar.writeTxn(() async {
      final f = await _db.isar.inspirationFragments.get(id);
      if (f == null) return;
      if (content != null) f.content = content;
      if (note != null) f.note = note;
      if (tag != null) f.tag = tag;
      if (bookTitle != null) f.bookTitle = bookTitle;
      f.updateTime = DateTime.now();
      await _db.isar.inspirationFragments.put(f);
    });
    await loadFragments();
  }

  Future<void> deleteFragment(int id) async {
    await _db.isar.writeTxn(() async { await _db.isar.inspirationFragments.delete(id); });
    await loadFragments();
  }
}
