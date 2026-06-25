import 'package:isar/isar.dart';
import 'character_event.dart'; // 【新增】引入事件模型

part 'character.g.dart';

/// 角色模型
/// 这是一个嵌入式对象，存放在 Book 或 CharacterGroup 中
@embedded
class Character {
  /// 角色名称
  String? name;

  /// 头像路径
  String? avatarPath;

  /// 角色定位/身份
  String? role;

  /// 一句话简介
  String? description;

  /// 排序索引
  int orderIndex = 0;

  // --- 详情页数据 ---

  /// 详细生平 (总括/设定文案)
  String? bio;

  /// 标签列表
  List<String>? tags;

  /// 【新增】生平事件时间轴
  List<CharacterEvent>? lifeEvents;
}
