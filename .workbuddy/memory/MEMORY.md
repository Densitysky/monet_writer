# MEMORY.md - 长期记忆

## 项目概况
- **项目名称**：Monet Writer (墨奈写作)
- **技术栈**：Flutter + Dart >=3.2.0, Isar NoSQL, Provider 状态管理, flutter_quill 富文本
- **平台**：Android, iOS, Windows, macOS, Linux 五端
- **核心功能**：小说写作工具（书架管理、富文本编辑、角色/大纲管理、AI助手、LAN同步、ZIP备份、EPUB导出）

## 架构关键决策
1. **内嵌对象策略**：Book 为聚合根，大纲/角色使用 Isar @embedded 内嵌，非 IsarLinks 关系
2. **WritingProvider Mixin 拆分**：9个Mixin（editor/chapter/character/outline/history/search/trash/export/ai_extraction）
3. **双存储策略**：Chapter 同时存 content(纯文本) + contentDelta(Delta JSON)
4. **三明治 Prompt**：baseSystemPrompt → userCustomPreference → formatConstraint
5. **流式文件传输**：LAN同步和备份恢复均使用流式处理避免OOM
6. **独立废纸篓表**：TrashedChapter 独立 @collection，非软删除标记
7. **双平台路由**：width>800px → DesktopHomePage(侧边栏), else → MainScaffold(底部导航)
8. **双主题风格**：modern(Material 3 拟物风) + flat(极简扁平风)

## 项目文件统计
- 127个 Dart 源文件（lib/目录）
- 14个数据模型（7个 @collection + 8个 @embedded）
- 7个服务类
- 3个全局 Provider + 1个写作 Provider（9个 Mixin）
- 最大单文件：DesktopStatisticsView (33KB)

## 已完成工作
- 2026-04-11: 完成项目完整解读文档，覆盖全部12个章节
