import 'package:isar/isar.dart';
import 'outline_node.dart';

part 'outline_tab.g.dart';

enum OutlineType {
  text, // 文本模式 (World view, settings)
  list, // 列表模式 (Timeline, inventory)
}

@embedded
class OutlineTab {
  String? id;    // 唯一标识 (暂时用时间戳字符串)
  String? title; // 页签名称 (如：世界观)

  @enumerated
  OutlineType type = OutlineType.text;

  // --- 数据存储 (二选一) ---

  String? textContent; // 文本型数据

  List<OutlineNode>? nodes; // 列表型数据
}
