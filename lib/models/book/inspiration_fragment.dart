import 'package:isar/isar.dart';

part 'inspiration_fragment.g.dart';

/// 灵感碎片模型
@collection
class InspirationFragment {
  Id id = Isar.autoIncrement;

  late String content;     // 碎片主内容

  String? note;            // 补充说明

  String tag = '其他';     // 标签: 角色/情节/场景/金句/世界观/其他

  String? bookTitle;       // 关联书籍名

  late DateTime createTime; // 创建时间
  late DateTime updateTime; // 更新时间
}
