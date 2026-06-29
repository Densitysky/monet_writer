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
8. **三主题风格 × 三配色方案**：`AppThemeStyle` (modern/flat/golden) × `ColorPalette` (goldenAngle/chinese/japanese)，黄金体系共用 `StyleConfig.golden` 统一字体格式
9. **个人主页拖拽 Header**：内容区 Positioned 钉底 + 拖拽把手，三档磁吸 (220/320/500)，封面 3:4 竖图裁剪

## 主题配色说明
- 金律：137.5° 色相旋转，用户自选 seedColor，ColorScheme 手动构建
- 中国色：种子色 靛青 #1661AB，fromSeed + 暖纸底色覆盖
- 和色：种子色 瑠璃 #1E50A2，fromSeed + 和纸底色覆盖
- 24 色色盘保留三套（goldenAngleColors / chineseColors / japaneseColors）
- 色盘弹窗选色自动切换对应 ColorPalette

## 项目文件统计
- 127个 Dart 源文件（lib/目录）
- 14个数据模型（7个 @collection + 8个 @embedded）
- 7个服务类
- 3个全局 Provider + 1个写作 Provider（9个 Mixin）
- 最大单文件：DesktopStatisticsView (33KB)

## 已完成工作
- 2026-04-11: 完成项目完整解读文档，覆盖全部12个章节
