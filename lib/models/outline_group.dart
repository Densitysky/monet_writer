import 'package:isar/isar.dart';
import 'custom_outline.dart';

part 'outline_group.g.dart';

@embedded
class OutlineGroup {
  String? title;

  // 组内的大纲列表
  List<CustomOutline>? outlines;

  // 辅助方法：获取安全的列表
  List<CustomOutline> get safeOutlines => outlines ?? [];
}
