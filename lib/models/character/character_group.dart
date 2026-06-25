import 'package:isar/isar.dart';
import 'character.dart';

part 'character_group.g.dart';

/// 角色分组模型 (类似文件夹)
@embedded
class CharacterGroup {
  /// 分组标题 (如: 主角团, 敌对势力)
  String? title;

  /// 组内的角色列表
  List<Character>? characters;

  /// 辅助方法：获取安全的列表 (防止 null)
  List<Character> get safeCharacters => characters ?? [];
}
