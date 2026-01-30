# ✍️ 落笔 (Monet Writer)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=flat&logo=dart)
![Isar](https://img.shields.io/badge/Database-Isar-purple?style=flat)
![Material 3](https://img.shields.io/badge/Design-Material%203-blueviolet?style=flat)
![License](https://img.shields.io/badge/license-MIT-green)

**一款基于 Material Design 3 的沉浸式小说创作工具，融合 AI 辅助与本地化高性能存储。**

[功能特性] • [安装指南] • [开发构建] • [贡献]

</div>

## 📖 简介

**落笔 (Monet Writer)** 专为网文作者和创意写作者设计。它不仅仅是一个编辑器，更是一个包含大纲策划、角色管理和 AI 辅助的完整创作系统。应用完全遵循 Material Design 3 设计规范，支持动态取色主题，提供优雅、无干扰的写作体验。

## ✨ 核心特性

### 🖋️ 沉浸式写作台
- **双侧边栏设计**：左侧管理章节目录，右侧快速查阅大纲与角色，写作不中断。
- **智能高亮**：自动识别并高亮文中的角色名字，增强阅读与编辑体验。
- **辅助工具栏**：提供长按连发的光标移动、常用标点快捷键及撤销/重做功能。

### 🤖 AI 深度集成 (AI Lab)
- **多模型支持**：内置 Google Gemini, OpenAI, SiliconFlow, DeepSeek 等主流模型接口。
- **角色智能提取**：一键分析当前章节正文，自动提取登场角色并生成简介。
- **设定辅助**：根据正文内容自动补全角色生平、生成大纲灵感。

### 👥 角色与世界观管理
- **角色经历时间轴**：独创的混合布局，支持以时间轴卡片形式记录角色生平大事件，支持拖拽排序。
- **分组管理**：支持角色分组（如“主角团”、“反派”），层级清晰。
- **动态大纲**：分为“宏观·设定”（Logline、世界观）与“剧情·细纲”（时间线节点），支持自定义多类型设定集。

### 📚 书架与数据
- **本地优先**：使用高性能 Isar 数据库，数据完全本地存储，安全无忧。
- **动态视觉**：自动根据书名生成马卡龙色系封面，告别单调的灰色占位图。
- **多格式导出**：支持导出为 TXT 和标准 EPUB 电子书格式。

## 🛠️ 技术栈

* **框架**: [Flutter](https://flutter.dev/)
* **数据库**: [Isar](https://isar.dev/) (NoSQL, 高性能)
* **状态管理**: Provider
* **UI 风格**: Material Design 3 (MD3)
* **网络**: Http (AI API 调用)
