part of '../writing_provider.dart';

/// 零件四：大纲管理、世界观设定及节点拖拽逻辑
mixin WritingOutlineMixin on WritingProviderBase {

  // ==================== 核心大纲 ====================

  Future<void> updateCoreOutline(String description, String outline) async {
    await _updateBook((freshBook) {
      freshBook.description = description;
      freshBook.outline = outline;
    });
  }

  // ==================== 自定义剧情节点 ====================

  Future<void> addPlotNode(String title, String content) async {
    final newNode = CustomOutline()..title = title..content = content;
    await _updateBook((freshBook) {
      List<CustomOutline> list = freshBook.customOutlines?.toList() ?? [];
      list.add(newNode);
      freshBook.customOutlines = list;
    });
  }

  Future<void> updatePlotNode(int index, String title, String content) async {
    await _updateBook((freshBook) {
      List<CustomOutline> list = freshBook.customOutlines?.toList() ?? [];
      if (index < list.length) {
        var node = list[index];
        node.title = title;
        node.content = content;
        list[index] = node;
        freshBook.customOutlines = list;
      }
    });
  }

  Future<void> deletePlotNode(int index) async {
    await _updateBook((freshBook) {
      List<CustomOutline> list = freshBook.customOutlines?.toList() ?? [];
      if (index < list.length) {
        list.removeAt(index);
        freshBook.customOutlines = list;
      }
    });
  }

  Future<void> reorderPlotNodes(int oldIndex, int newIndex) async {
    await _updateBook((freshBook) {
      List<CustomOutline> list = freshBook.customOutlines?.toList() ?? [];
      if (oldIndex < list.length) {
        if (oldIndex < newIndex) newIndex -= 1;
        final item = list.removeAt(oldIndex);
        if (newIndex <= list.length) {
          list.insert(newIndex, item);
        } else {
          list.add(item);
        }
        freshBook.customOutlines = list;
      }
    });
  }

  // ==================== 世界观设定标签页 (Tabs) ====================

  Future<void> createSettingsTab(String title, OutlineType type) async {
    final newTab = OutlineTab()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..type = type
      ..textContent = ''
      ..nodes = [];

    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      tabs.add(newTab);
      freshBook.settingsTabs = tabs;
    });
  }

  Future<void> renameSettingsTab(int index, String newTitle) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (index < tabs.length) {
        tabs[index].title = newTitle;
        freshBook.settingsTabs = tabs;
      }
    });
  }

  Future<void> deleteSettingsTab(int index) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (index < tabs.length) {
        tabs.removeAt(index);
        freshBook.settingsTabs = tabs;
      }
    });
  }

  Future<void> updateTabContent(int index, String content) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (index < tabs.length) {
        tabs[index].textContent = content;
        freshBook.settingsTabs = tabs;
      }
    });
  }

  // ==================== 世界观设定节点 (Nodes in Tabs) ====================

  Future<void> addNodeToTab(int tabIndex, String title, String content) async {
    final newNode = OutlineNode()..title = title..content = content;
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (tabIndex < tabs.length) {
        var tab = tabs[tabIndex];
        List<OutlineNode> nodes = tab.nodes?.toList() ?? [];
        nodes.add(newNode);
        tab.nodes = nodes;
        tabs[tabIndex] = tab;
        freshBook.settingsTabs = tabs;
      }
    });
  }

  Future<void> updateNodeInTab(int tabIndex, int nodeIndex, String title, String content) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (tabIndex < tabs.length) {
        var tab = tabs[tabIndex];
        List<OutlineNode> nodes = tab.nodes?.toList() ?? [];
        if (nodeIndex < nodes.length) {
          nodes[nodeIndex].title = title;
          nodes[nodeIndex].content = content;
          tab.nodes = nodes;
          tabs[tabIndex] = tab;
          freshBook.settingsTabs = tabs;
        }
      }
    });
  }

  Future<void> deleteNodeInTab(int tabIndex, int nodeIndex) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (tabIndex < tabs.length) {
        var tab = tabs[tabIndex];
        List<OutlineNode> nodes = tab.nodes?.toList() ?? [];
        if (nodeIndex < nodes.length) {
          nodes.removeAt(nodeIndex);
          tab.nodes = nodes;
          tabs[tabIndex] = tab;
          freshBook.settingsTabs = tabs;
        }
      }
    });
  }

  Future<void> reorderNodesInTab(int tabIndex, int oldIndex, int newIndex) async {
    await _updateBook((freshBook) {
      List<OutlineTab> tabs = freshBook.settingsTabs?.toList() ?? [];
      if (tabIndex < tabs.length) {
        var tab = tabs[tabIndex];
        List<OutlineNode> nodes = tab.nodes?.toList() ?? [];
        if (oldIndex < nodes.length) {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = nodes.removeAt(oldIndex);
          if (newIndex <= nodes.length) {
            nodes.insert(newIndex, item);
          } else {
            nodes.add(item);
          }
          tab.nodes = nodes;
          tabs[tabIndex] = tab;
          freshBook.settingsTabs = tabs;
        }
      }
    });
  }
}