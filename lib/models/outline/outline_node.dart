import 'package:isar/isar.dart';

part 'outline_node.g.dart';

@embedded
class OutlineNode {
  String? title;   // 节点标题 (如：事件名)
  String? content; // 节点内容 (如：事件详情)

  // 预留颜色或标记字段，方便未来扩展
  int colorIndex = 0;
}
