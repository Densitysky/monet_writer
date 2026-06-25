import 'package:isar/isar.dart';
import 'package:monet_writer/models/outline/custom_outline.dart';
import 'package:monet_writer/models/outline/outline_group.dart';
import 'package:monet_writer/models/character/character.dart';
import 'package:monet_writer/models/character/character_group.dart';
import 'package:monet_writer/models/outline/outline_tab.dart';
import 'package:monet_writer/models/outline/outline_node.dart';
import 'package:monet_writer/models/character/character_event.dart';

part 'book.g.dart';

@collection
class Book {
  Id id = Isar.autoIncrement;

  late String title;
  String? coverPath;
  String? description; // 核心梗概 (Logline)

  // 作者/笔名
  String? authorName;

  // 状态：0=连载中, 1=已完结
  int status = 0;

  late DateTime createdAt;
  late DateTime updatedAt;

  int wordCount = 0;
  bool isDeleted = false;
  int? lastChapterId;

  // --- 大纲模块 ---

  String? outline; // 核心总纲
  String? volumeOutline; // (暂留，未来可能合并)

  // 主线剧情 (对应 "剧情·细纲" Tab)
  List<CustomOutline>? customOutlines;

  // (旧) 大纲分组 - 留着兼容防止报错，后续清理
  List<OutlineGroup>? outlineGroups;

  // 自定义设定集 (对应 "宏观·设定" 下的自定义 Tabs)
  List<OutlineTab>? settingsTabs;

  // --- 角色管理模块 ---

  /// 根目录下的角色
  List<Character>? characters;

  /// 角色分组
  List<CharacterGroup>? characterGroups;
}
