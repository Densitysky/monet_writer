part of '../writing_provider.dart';

/// 零件三：角色库、分组库、时间轴以及智能角色分析逻辑
mixin WritingCharacterMixin on WritingProviderBase {

  // ==================== 角色缓存与刷新 ====================

  @override
  void _refreshNameCache() {
    final names = <String>{};
    if (book.characters != null) {
      for (var c in book.characters!) {
        if (c.name != null && c.name!.isNotEmpty) names.add(c.name!);
      }
    }
    if (book.characterGroups != null) {
      for (var g in book.characterGroups!) {
        if (g.characters != null) {
          for (var c in g.characters!) {
            if (c.name != null && c.name!.isNotEmpty) names.add(c.name!);
          }
        }
      }
    }
    _cachedCharacterNames = names;
    contentController.updateKeywords(names);
  }

  // ==================== 角色组管理 ====================

  Future<void> createCharacterGroup(String title) async {
    await _updateBook((freshBook) {
      List<CharacterGroup> groups = freshBook.characterGroups?.toList() ?? [];
      groups.add(CharacterGroup()..title = title);
      freshBook.characterGroups = groups;
    });
  }

  Future<void> renameCharacterGroup(int index, String newName) async {
    await _updateBook((freshBook) {
      var groups = freshBook.characterGroups?.toList() ?? [];
      if (index < groups.length) {
        groups[index].title = newName;
        freshBook.characterGroups = groups;
      }
    });
  }

  Future<void> deleteCharacterGroup(int index) async {
    await _updateBook((freshBook) {
      var groups = freshBook.characterGroups?.toList() ?? [];
      if (index < groups.length) {
        groups.removeAt(index);
        freshBook.characterGroups = groups;
      }
    });
  }

  // ==================== 角色实体管理 ====================

  Future<void> createCharacter({required String name, String? desc}) async {
    await _updateBook((freshBook) {
      List<Character> chars = freshBook.characters?.toList() ?? [];
      chars.add(Character()..name = name..description = desc);
      freshBook.characters = chars;
    });
    _refreshNameCache();
  }

  @override // <--- 必须加上 override，实现 Base 里的通道
  Future<void> batchAddCharacters(List<dynamic> charList) async {
    await _updateBook((freshBook) {
      freshBook.characters ??= [];
      for (var char in charList) {
        if (char is Map) {
          final newChar = Character()
            ..name = char['name']?.toString()
            ..description = char['description']?.toString()
            ..role = char['role']?.toString()
            ..bio = char['bio']?.toString();
          freshBook.characters!.add(newChar);
        }
      }
    });
    _refreshNameCache();
  }

  Future<void> updateCharacter(int index, {
    int? groupIndex,
    String? newName,
    String? newDesc,
    String? newAvatarPath,
    String? newBio,
    List<String>? newTags,
  }) async {
    await _updateBook((freshBook) {
      Character char;
      if (groupIndex == null) {
        var chars = freshBook.characters?.toList() ?? [];
        if (index >= chars.length) return;
        char = chars[index];
        if (newName != null) char.name = newName;
        if (newDesc != null) char.description = newDesc;
        if (newAvatarPath != null) char.avatarPath = newAvatarPath;
        if (newBio != null) char.bio = newBio;
        if (newTags != null) char.tags = newTags;
        chars[index] = char;
        freshBook.characters = chars;
      } else {
        var groups = freshBook.characterGroups?.toList() ?? [];
        if (groupIndex >= groups.length) return;
        var group = groups[groupIndex];
        var chars = group.characters?.toList() ?? [];
        if (index >= chars.length) return;
        char = chars[index];
        if (newName != null) char.name = newName;
        if (newDesc != null) char.description = newDesc;
        if (newAvatarPath != null) char.avatarPath = newAvatarPath;
        if (newBio != null) char.bio = newBio;
        if (newTags != null) char.tags = newTags;
        chars[index] = char;
        group.characters = chars;
        groups[groupIndex] = group;
        freshBook.characterGroups = groups;
      }
    });
    if (newName != null) _refreshNameCache();
  }

  Future<void> deleteCharacter(int index, {int? groupIndex}) async {
    await _updateBook((freshBook) {
      if (groupIndex == null) {
        var chars = freshBook.characters?.toList() ?? [];
        if (index < chars.length) {
          chars.removeAt(index);
          freshBook.characters = chars;
        }
      } else {
        var groups = freshBook.characterGroups?.toList() ?? [];
        if (groupIndex < groups.length) {
          var group = groups[groupIndex];
          var chars = group.characters?.toList() ?? [];
          if (index < chars.length) {
            chars.removeAt(index);
            group.characters = chars;
            groups[groupIndex] = group;
            freshBook.characterGroups = groups;
          }
        }
      }
    });
    _refreshNameCache();
  }

  Future<void> moveCharacter({required int fromIndex, required int? fromGroupIndex, required int? toGroupIndex}) async {
    await _updateBook((freshBook) {
      Character? targetItem;
      if (fromGroupIndex == null) {
        List<Character> src = freshBook.characters?.toList() ?? [];
        if (fromIndex < src.length) { targetItem = src.removeAt(fromIndex); freshBook.characters = src; }
      } else {
        List<CharacterGroup> groups = freshBook.characterGroups?.toList() ?? [];
        if (fromGroupIndex < groups.length) {
          var group = groups[fromGroupIndex];
          List<Character> src = group.characters?.toList() ?? [];
          if (fromIndex < src.length) { targetItem = src.removeAt(fromIndex); group.characters = src; groups[fromGroupIndex] = group; freshBook.characterGroups = groups; }
        }
      }
      if (targetItem == null) return;

      if (toGroupIndex == null) {
        List<Character> tgt = freshBook.characters?.toList() ?? [];
        tgt.add(targetItem);
        freshBook.characters = tgt;
      } else {
        List<CharacterGroup> groups = freshBook.characterGroups?.toList() ?? [];
        if (toGroupIndex < groups.length) {
          var group = groups[toGroupIndex];
          List<Character> tgt = group.characters?.toList() ?? [];
          tgt.add(targetItem);
          group.characters = tgt;
          groups[toGroupIndex] = group;
          freshBook.characterGroups = groups;
        } else {
          List<Character> tgt = freshBook.characters?.toList() ?? [];
          tgt.add(targetItem);
          freshBook.characters = tgt;
        }
      }
    });
    _refreshNameCache();
  }

  // ==================== 角色经历/时间轴管理 ====================

  Future<void> addCharacterEvent(int charIndex, {int? groupIndex, required String title, String? content, String? timePoint}) async {
    final event = CharacterEvent(title: title, content: content, timePoint: timePoint);
    await _updateCharacterEvents(charIndex, groupIndex, (events) {
      events.add(event);
    });
  }

  Future<void> updateCharacterEvent(int charIndex, int eventIndex, {int? groupIndex, String? title, String? content, String? timePoint}) async {
    await _updateCharacterEvents(charIndex, groupIndex, (events) {
      if (eventIndex < events.length) {
        var e = events[eventIndex];
        if (title != null) e.title = title;
        if (content != null) e.content = content;
        if (timePoint != null) e.timePoint = timePoint;
        events[eventIndex] = e;
      }
    });
  }

  Future<void> deleteCharacterEvent(int charIndex, int eventIndex, {int? groupIndex}) async {
    await _updateCharacterEvents(charIndex, groupIndex, (events) {
      if (eventIndex < events.length) {
        events.removeAt(eventIndex);
      }
    });
  }

  Future<void> reorderCharacterEvents(int charIndex, int oldIndex, int newIndex, {int? groupIndex}) async {
    await _updateCharacterEvents(charIndex, groupIndex, (events) {
      if (oldIndex < events.length) {
        if (oldIndex < newIndex) newIndex -= 1;
        final item = events.removeAt(oldIndex);
        if (newIndex <= events.length) {
          events.insert(newIndex, item);
        } else {
          events.add(item);
        }
      }
    });
  }

  Future<void> _updateCharacterEvents(int charIndex, int? groupIndex, void Function(List<CharacterEvent>) action) async {
    await _updateBook((freshBook) {
      Character char;
      List<CharacterEvent> events;

      if (groupIndex == null) {
        var chars = freshBook.characters?.toList() ?? [];
        if (charIndex >= chars.length) return;
        char = chars[charIndex];
        events = char.lifeEvents?.toList() ?? [];
        action(events);
        char.lifeEvents = events;
        chars[charIndex] = char;
        freshBook.characters = chars;
      } else {
        var groups = freshBook.characterGroups?.toList() ?? [];
        if (groupIndex >= groups.length) return;
        var group = groups[groupIndex];
        var chars = group.characters?.toList() ?? [];
        if (charIndex >= chars.length) return;
        char = chars[charIndex];
        events = char.lifeEvents?.toList() ?? [];
        action(events);
        char.lifeEvents = events;
        chars[charIndex] = char;
        group.characters = chars;
        groups[groupIndex] = group;
        freshBook.characterGroups = groups;
      }
    });
  }

  // ==================== AI 分析辅助 ====================

  bool isAnalyzing(String charName) => _analyzingCharacters.contains(charName);

  Future<void> analyzeCharacterWithAi(AiConfig config, String charName, {required int index, int? groupIndex}) async {
    // 【核心修复 1：防并发锁】拦截狂点按钮导致的重复发包
    if (isAnalyzing(charName)) throw Exception('该角色正在深度分析中，请稍作等待');

    _analyzingCharacters.add(charName);
    notifyListeners();

    try {
      final contextText = await getRecentContent(limit: 5);
      if (contextText.isEmpty) throw Exception('暂无正文内容，请先在左侧输入章节内容');

      final systemPrompt = await PromptManager.getSystemPrompt(PromptManager.SCENE_CHAR_ANALYSIS);

      final userPrompt = '''
角色名字：$charName
小说正文片段：
$contextText
''';

      final response = await AiService.generateText(
        config,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      final cleanJsonStr = AiService.cleanJsonString(response);
      final Map<String, dynamic> data = jsonDecode(cleanJsonStr);

      await updateCharacter(
        index,
        groupIndex: groupIndex,
        newDesc: data['description']?.toString(),
        newBio: data['bio']?.toString(),
        newTags: data['tags'] != null ? (data['tags'] as List).map((e) => e.toString()).toList() : null,
      );

      // 【核心修复 2：JSON 容错解析】防止格式破损抛错
      if (data['events'] != null && data['events'] is List) {
        await _updateCharacterEvents(index, groupIndex, (events) {
          for (var e in data['events']) {
            events.add(CharacterEvent(
              timePoint: e['timePoint']?.toString(),
              title: e['title']?.toString(),
              content: e['content']?.toString(),
            ));
          }
        });
      }

    } catch (e) {
      debugPrint('AI 分析失败: $e');
      // 【核心修复 3：将异常抛给 UI 弹窗】
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _analyzingCharacters.remove(charName);
      notifyListeners();
    }
  }
}