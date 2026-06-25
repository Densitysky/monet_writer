import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:monet_writer/providers/writing_provider.dart';
import 'package:monet_writer/providers/user_provider.dart'; // 【新增】引入用户阅读主题
import 'package:monet_writer/providers/theme_provider.dart'; // 【新增】引入双引擎风格
import 'package:monet_writer/models/character/character.dart';
import 'package:monet_writer/models/character/character_event.dart';
import 'package:monet_writer/services/ai_service.dart';
import 'package:monet_writer/widgets/monet_avatar.dart';

import 'package:monet_writer/utils/monet_animations.dart';

class CharacterProfilePage extends StatefulWidget {
  final Character character;
  final int index;
  final int? groupIndex;

  const CharacterProfilePage({
    super.key,
    required this.character,
    required this.index,
    this.groupIndex,
  });

  @override
  State<CharacterProfilePage> createState() => _CharacterProfilePageState();
}

class _CharacterProfilePageState extends State<CharacterProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _tagInputCtrl;

  late String? _avatarPath;
  late List<String> _tags;
  Color? _themeColor;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _nameCtrl = TextEditingController(text: widget.character.name);
    _descCtrl = TextEditingController(text: widget.character.description);
    _bioCtrl = TextEditingController(text: widget.character.bio);
    _tagInputCtrl = TextEditingController();

    _avatarPath = widget.character.avatarPath;
    _tags = List.from(widget.character.tags ?? []);

    _extractColor();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<WritingProvider>();
    final char = _getCurrentCharacter(provider);

    if (char != null) {
      if (char.bio != _bioCtrl.text && char.bio != null) {
        _bioCtrl.text = char.bio!;
      }
      if (char.description != _descCtrl.text && char.description != null) {
        _descCtrl.text = char.description!;
      }
      if (char.tags != null && char.tags.toString() != _tags.toString()) {
        setState(() {
          _tags = List.from(char.tags!);
        });
      }
    }
  }

  Character? _getCurrentCharacter(WritingProvider provider) {
    if (widget.groupIndex == null) {
      if (provider.book.characters != null && widget.index < provider.book.characters!.length) {
        return provider.book.characters![widget.index];
      }
    } else {
      if (provider.book.characterGroups != null && widget.groupIndex! < provider.book.characterGroups!.length) {
        final group = provider.book.characterGroups![widget.groupIndex!];
        if (group.characters != null && widget.index < group.characters!.length) {
          return group.characters![widget.index];
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _bioCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _saveCharacter() {
    context.read<WritingProvider>().updateCharacter(
      widget.index,
      groupIndex: widget.groupIndex,
      newName: _nameCtrl.text,
      newDesc: _descCtrl.text,
      newBio: _bioCtrl.text,
      newAvatarPath: _avatarPath,
      newTags: _tags,
    );
  }

  Future<void> _extractColor() async {
    if (_avatarPath == null) {
      if (mounted) setState(() => _isLoadingColor = false);
      return;
    }
    final file = File(_avatarPath!);
    if (!file.existsSync()) {
      if (mounted) setState(() => _isLoadingColor = false);
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(FileImage(file));
      if (mounted) {
        setState(() {
          _themeColor = palette.dominantColor?.color;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingColor = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: '裁切头像',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(title: '裁切头像', aspectRatioLockEnabled: true),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _avatarPath = croppedFile.path;
        _isLoadingColor = true;
      });
      _extractColor();
      _saveCharacter();
    }
  }

  void _syncWithAi() {
    final aiProvider = context.read<AiProvider>();
    if (aiProvider.config.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在设置中配置 AI API Key')));
      return;
    }
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写角色名字')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ 任务已在后台开始，您可以继续其他操作...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        )
    );

    context.read<WritingProvider>().analyzeCharacterWithAi(
      aiProvider.config,
      _nameCtrl.text,
      index: widget.index,
      groupIndex: widget.groupIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = context.watch<UserProvider>().currentTheme; // 阅读主题（提供背景色和文字色）
    final isFlat = context.watch<ThemeProvider>().themeStyle == AppThemeStyle.flat; // 视觉风格
    final provider = context.watch<WritingProvider>();

    final isAnalyzing = provider.isAnalyzing(_nameCtrl.text);
    final primaryColor = _themeColor ?? theme.colorScheme.primary;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) => _saveCharacter(),
      child: Scaffold(
        backgroundColor: currentTheme.backgroundColor, // 完美融入当前阅读底色
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 320, // 加高头部，展现大片感
              pinned: true,
              backgroundColor: primaryColor,
              // 返回键在渐变遮罩上统一用白色
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. 头像背景图
                    if (_avatarPath != null)
                      Image.file(File(_avatarPath!), fit: BoxFit.cover),

                    // 2. 底层轻微毛玻璃（如果你喜欢的话可以保留，或者注释掉显得更清晰）
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(color: Colors.black.withValues(alpha: 0.2)),
                    ),

                    // 3. 【极光渐变遮罩】让底部的文字永远清晰，并向上过渡到透明
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8), // 底部极黑
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent, // 顶部透明
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 4. 头像与名字容器
                    Positioned(
                      bottom: 80, // 留出下方 TabBar 的位置
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MonetAvatar(
                            avatarPath: _avatarPath,
                            name: _nameCtrl.text,
                            size: 110,
                            heroTag: 'char_img_${widget.groupIndex ?? "root"}_${widget.index}',
                            onTap: _pickAvatar,
                            showBorder: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameCtrl.text.isEmpty ? '未命名角色' : _nameCtrl.text,
                            style: const TextStyle(
                              color: Colors.white, // 强制纯白，极具电影感
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 收起时的标题
                title: innerBoxIsScrolled ? Text(_nameCtrl.text, style: const TextStyle(color: Colors.white)) : null,
                centerTitle: true,
              ),

              // 【抽屉式资料卡头部】将 TabBar 包装在一个带有上圆角的纯净容器中
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(54),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: currentTheme.backgroundColor, // 资料卡底色
                    borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 30.0)), // 现代风大圆角，极简风直角
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: currentTheme.textColor.withValues(alpha: 0.5),
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent, // 去掉底部分割线
                    tabs: const [
                      Tab(text: '基础资料'),
                      Tab(text: '生平档案')
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: Container(
            color: currentTheme.backgroundColor, // 填满下方的背景
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(theme, currentTheme, isFlat),
                _buildBioTab(theme, currentTheme, isFlat),
              ],
            ),
          ),
        ),

        // 【按钮升级】自带阴影或纯平色块
        floatingActionButton: isAnalyzing
            ? FloatingActionButton.extended(
          onPressed: null,
          icon: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: currentTheme.textColor)),
          label: Text('AI 分析中...', style: TextStyle(color: currentTheme.textColor)),
          backgroundColor: currentTheme.textColor.withValues(alpha: 0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)),
        )
            : _buildFab(theme, isFlat),
      ),
    );
  }

  Widget _buildFab(ThemeData theme, bool isFlat) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        if (_tabController.index == 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_ai_sync',
                onPressed: _syncWithAi,
                elevation: isFlat ? 0 : 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: const Icon(Icons.auto_awesome),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'fab_add_event',
                onPressed: () => _showEventEditDialog(context, isFlat: isFlat),
                elevation: isFlat ? 0 : 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)),
                icon: const Icon(Icons.add),
                label: const Text('添加经历'),
              ),
            ],
          );
        } else {
          return FloatingActionButton.extended(
            heroTag: 'fab_ai_sync_main',
            onPressed: _syncWithAi,
            elevation: isFlat ? 0 : 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0)),
            backgroundColor: theme.colorScheme.primaryContainer,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 同步'),
          );
        }
      },
    );
  }

  // 【专属沉浸式输入区构建器】
  Widget _buildDossierInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    int? maxLines = 1,
    int? minLines,
    IconData? icon,
    required WritingTheme currentTheme,
    required bool isFlat,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: currentTheme.textColor.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          style: TextStyle(color: currentTheme.textColor, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.2)),
            filled: true,
            fillColor: currentTheme.textColor.withValues(alpha: 0.05), // 高级感色块
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0), // 动态圆角
              borderSide: BorderSide.none, // 永远不要边框
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoTab(ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        _buildDossierInput(
          controller: _nameCtrl,
          label: '角色姓名',
          icon: Icons.person_outline,
          currentTheme: currentTheme,
          isFlat: isFlat,
          onChanged: (_) => setState((){}),
        ),
        const SizedBox(height: 24),
        _buildDossierInput(
          controller: _descCtrl,
          label: '一句话简介 (定位)',
          icon: Icons.lightbulb_outline,
          hint: '例如：深藏不露的扫地僧，表面贪财实则重情重义...',
          maxLines: 3,
          currentTheme: currentTheme,
          isFlat: isFlat,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(Icons.sell_outlined, size: 14, color: currentTheme.textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text('角色标签', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.5))),
            const Spacer(),
            BouncingWidget(
              onTap: () => _showAddTagDialog(isFlat, currentTheme),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 14, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text('添加', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tags.isEmpty)
          Text('暂无标签，给角色贴上几个专属 Tag 吧', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3), fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), // 水彩风底色
              deleteIconColor: theme.colorScheme.primary,
              side: BorderSide.none, // 无边框
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 8.0)),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildBioTab(ThemeData theme, WritingTheme currentTheme, bool isFlat) {
    final provider = context.watch<WritingProvider>();
    final char = _getCurrentCharacter(provider);
    final events = char?.lifeEvents ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDossierInput(
                  controller: _bioCtrl,
                  label: '生平总括 / 核心设定',
                  icon: Icons.menu_book,
                  hint: '在此书写角色的出身、性格成因等基调设定...',
                  maxLines: null,
                  minLines: 5,
                  currentTheme: currentTheme,
                  isFlat: isFlat,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.timeline, size: 14, color: currentTheme.textColor.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text('经历时间轴', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        if (events.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('暂无经历事件，点击右下角添加', style: TextStyle(color: currentTheme.textColor.withValues(alpha: 0.3)))),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Column(
                            children: [
                              Container(width: 2, height: 16, color: currentTheme.textColor.withValues(alpha: 0.1)),
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(child: Container(width: 2, color: currentTheme.textColor.withValues(alpha: 0.1))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            color: currentTheme.textColor.withValues(alpha: 0.05), // 高级色块
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0), side: BorderSide.none),
                            child: InkWell(
                              onTap: () => _showEventEditDialog(context, event: event, index: index, isFlat: isFlat),
                              onLongPress: () => _confirmDeleteEvent(context, index),
                              borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (event.timePoint != null && event.timePoint!.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(isFlat ? 2.0 : 6.0),
                                            ),
                                            child: Text(
                                              event.timePoint!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            event.title ?? '未命名事件',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: currentTheme.textColor, fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event.content != null && event.content!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        event.content!,
                                        style: TextStyle(fontSize: 13, color: currentTheme.textColor.withValues(alpha: 0.7), height: 1.5),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: events.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  void _showAddTagDialog(bool isFlat, WritingTheme currentTheme) {
    _tagInputCtrl.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 20.0)),
        title: const Text('添加专属标签'),
        content: TextField(
          controller: _tagInputCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '例如：火系 / 腹黑',
            filled: true,
            fillColor: currentTheme.textColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 12.0))),
            onPressed: () {
              if (_tagInputCtrl.text.isNotEmpty) {
                setState(() => _tags.add(_tagInputCtrl.text));
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEventEditDialog(BuildContext context, {CharacterEvent? event, int? index, required bool isFlat}) {
    final titleCtrl = TextEditingController(text: event?.title);
    final contentCtrl = TextEditingController(text: event?.content);
    final timeCtrl = TextEditingController(text: event?.timePoint);
    final isEdit = event != null;

    final currentTheme = context.read<UserProvider>().currentTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
            color: currentTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isFlat ? 0.0 : 24.0))
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '编辑经历' : '添加经历', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: _buildDossierInput(controller: timeCtrl, label: '时间点', hint: '如: 18岁', currentTheme: currentTheme, isFlat: isFlat),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDossierInput(controller: titleCtrl, label: '事件概要', hint: '如: 拜入宗门', currentTheme: currentTheme, isFlat: isFlat),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDossierInput(controller: contentCtrl, label: '详细描述', hint: '发生了什么...', maxLines: 3, minLines: 3, currentTheme: currentTheme, isFlat: isFlat),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isFlat ? 4.0 : 16.0))),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    final provider = context.read<WritingProvider>();
                    if (isEdit) {
                      provider.updateCharacterEvent(
                        widget.index,
                        index!,
                        groupIndex: widget.groupIndex,
                        title: titleCtrl.text,
                        content: contentCtrl.text,
                        timePoint: timeCtrl.text,
                      );
                    } else {
                      provider.addCharacterEvent(
                        widget.index,
                        groupIndex: widget.groupIndex,
                        title: titleCtrl.text,
                        content: contentCtrl.text,
                        timePoint: timeCtrl.text,
                      );
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('保存记录', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, int eventIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除此经历？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<WritingProvider>().deleteCharacterEvent(widget.index, eventIndex, groupIndex: widget.groupIndex);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}