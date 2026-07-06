import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/inspirations_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/providers/user_provider.dart';
import 'package:monet_writer/utils/inspiration_tag_colors.dart';

class DesktopInspirationsView extends StatefulWidget {
  const DesktopInspirationsView({super.key});

  @override
  State<DesktopInspirationsView> createState() => _DesktopInspirationsViewState();
}

class _DesktopInspirationsViewState extends State<DesktopInspirationsView> {
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspirationsProvider>().loadFragments();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final inspirationsProvider = context.watch<InspirationsProvider>();

    final isPaper = themeProvider.isPaperOrParchment;
    final currentTheme = userProvider.currentTheme;
    final themeData = Theme.of(context);

    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final bgColor = (isPaper || isNeumorphic)
        ? themeData.scaffoldBackgroundColor
        : currentTheme.backgroundColor;

    final isDark = bgColor.computeLuminance() < 0.5;
    final textColor = currentTheme.textColor;
    final mutedColor = textColor.withValues(alpha: 0.5);
    final hintColor = textColor.withValues(alpha: 0.25);
    final borderColor = textColor.withValues(alpha: 0.08);
    final surfaceColor = isPaper
        ? themeData.colorScheme.surfaceContainerHighest
        : textColor.withValues(alpha: 0.03);

    final fragments = inspirationsProvider.filteredFragments;

    final activeTag = inspirationsProvider.activeTag;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ===== 顶部栏 =====
          _buildTopBar(
            context,
            inspirationsProvider,
            isPaper,
            textColor,
            mutedColor,
            hintColor,
            borderColor,
            isDark,
          ),

          // ===== 卡片列表 =====
          Expanded(
            child: fragments.isEmpty
                ? _buildEmptyState(textColor, hintColor, muteColor: mutedColor)
                : _buildCardGrid(
                    fragments,
                    inspirationsProvider,
                    isPaper,
                    textColor,
                    mutedColor,
                    hintColor,
                    borderColor,
                    surfaceColor,
                    currentTheme.backgroundColor,
                    themeProvider.seedColor,
                  ),
          ),

          // ===== 底部快捷输入栏 =====
          _buildQuickInputBar(
            inspirationsProvider,
            isPaper,
            textColor,
            mutedColor,
            hintColor,
            borderColor,
            surfaceColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    InspirationsProvider provider,
    bool isPaper,
    Color textColor,
    Color mutedColor,
    Color hintColor,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '灵感碎片',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              // 搜索按钮
              _SearchToggle(
                textColor: textColor,
                mutedColor: mutedColor,
                onToggle: (open) {
                  if (!open) provider.setSearchQuery('');
                },
                onChanged: provider.setSearchQuery,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 标签筛选
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: InspirationsProvider.availableTags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tag = InspirationsProvider.availableTags[index];
                final isActive = provider.activeTag == tag;
                return GestureDetector(
                  onTap: () => provider.setActiveTag(tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isActive ? textColor : borderColor,
                        width: 1,
                      ),
                      color: isActive ? textColor : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? (isPaper && !isDark ? Colors.white : bgColorOf(textColor))
                            : mutedColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardGrid(
    List<InspirationItem> fragments,
    InspirationsProvider provider,
    bool isPaper,
    Color textColor,
    Color mutedColor,
    Color hintColor,
    Color borderColor,
    Color surfaceColor,
    Color bgColor,
    Color seedColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridColumns = constraints.maxWidth > 900 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 158,
          ),
          itemCount: fragments.length + 1, // +1 for add card
          itemBuilder: (context, index) {
            if (index == fragments.length) {
              return _buildAddCard(
                isPaper, textColor, mutedColor, hintColor, borderColor, surfaceColor,
                onTap: () => _showCreateSheet(context, provider, textColor, mutedColor, isPaper),
              );
            }
            final fragment = fragments[index];
            return _buildFragmentCard(
              fragment,
              isPaper,
              textColor,
              mutedColor,
              hintColor,
              borderColor,
              surfaceColor,
              bgColor,
              seedColor,
              onTap: () => _showEditSheet(context, provider, fragment, textColor, mutedColor, isPaper),
              onDelete: () => _confirmDelete(context, provider, fragment),
            );
          },
        );
      },
    );
  }

  Widget _buildFragmentCard(
    InspirationItem fragment,
    bool isPaper,
    Color textColor,
    Color mutedColor,
    Color hintColor,
    Color borderColor,
    Color surfaceColor,
    Color bgColor,
    Color seedColor, {
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fragment.content,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fragment.note != null && fragment.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      fragment.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // 底部标签行
            Row(
              children: [
                _buildTagChip(fragment.tag, textColor, seedColor),
                if (fragment.bookTitle != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    fragment.bookTitle!,
                    style: TextStyle(fontSize: 11, color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Text(
                  _formatTime(fragment.updateTime),
                  style: TextStyle(fontSize: 11, color: hintColor),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close, size: 14, color: hintColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, Color textColor, Color seedColor) {
    final tagInfo = getInspirationTagColor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tagInfo.$1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: tagInfo.$2,
        ),
      ),
    );
  }

  Widget _buildAddCard(
    bool isPaper, Color textColor, Color mutedColor, Color hintColor,
    Color borderColor, Color surfaceColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            // 虚线边框
            CustomPaint(
              painter: _DashedBorderPainter(borderColor),
              size: Size.infinite,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: hintColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '快速记录',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '想到什么随时记下来',
                    style: TextStyle(fontSize: 12, color: hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInputBar(
    InspirationsProvider provider,
    bool isPaper,
    Color textColor,
    Color mutedColor,
    Color hintColor,
    Color borderColor,
    Color surfaceColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showCreateSheet(context, provider, textColor, mutedColor, isPaper),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '记录一个灵感...',
                  style: TextStyle(fontSize: 13, color: hintColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildPillButton('标签', mutedColor, borderColor),
          const SizedBox(width: 8),
          _buildPillButton('关联作品', mutedColor, borderColor),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showCreateSheet(context, provider, textColor, mutedColor, isPaper),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '记录',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPaper && !isDark ? Colors.white : bgColorOf(textColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(String label, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 16, color: mutedColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color hintColor, {required Color muteColor}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 56,
            color: hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有灵感碎片',
            style: TextStyle(fontSize: 15, color: muteColor),
          ),
          const SizedBox(height: 6),
          Text(
            '点击上方「+ 快速记录」或底部输入栏记录灵感',
            style: TextStyle(fontSize: 13, color: hintColor),
          ),
        ],
      ),
    );
  }

  // ===== 弹窗：新建/编辑 =====
  void _showCreateSheet(
    BuildContext context,
    InspirationsProvider provider,
    Color textColor,
    Color mutedColor,
    bool isPaper,
  ) {
    _showEditorSheet(context, provider, textColor, mutedColor, isPaper, fragment: null);
  }

  void _showEditSheet(
    BuildContext context,
    InspirationsProvider provider,
    InspirationItem fragment,
    Color textColor,
    Color mutedColor,
    bool isPaper,
  ) {
    _showEditorSheet(context, provider, textColor, mutedColor, isPaper, fragment: fragment);
  }

  void _showEditorSheet(
    BuildContext context,
    InspirationsProvider provider,
    Color textColor,
    Color mutedColor,
    bool isPaper, {
    InspirationItem? fragment,
  }) {
    final isEditing = fragment != null;
    final contentCtrl = TextEditingController(text: fragment?.content ?? '');
    final noteCtrl = TextEditingController(text: fragment?.note ?? '');
    String selectedTag = fragment?.tag ?? '其他';
    String selectedBook = fragment?.bookTitle ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? '编辑灵感' : '记录灵感',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 内容输入
                    TextField(
                      controller: contentCtrl,
                      autofocus: !isEditing,
                      maxLines: 4,
                      style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
                      decoration: InputDecoration(
                        hintText: '写下灵感...',
                        hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 备注
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, color: mutedColor, height: 1.4),
                      decoration: InputDecoration(
                        hintText: '补充说明 (可选)',
                        hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.5), fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 标签选择
                    Text('标签', style: TextStyle(fontSize: 12, color: mutedColor)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: InspirationsProvider.availableTags
                          .where((t) => t != '全部')
                          .map((tag) {
                        final isSelected = selectedTag == tag;
                        final tagInfo = getInspirationTagColor(tag);
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedTag = tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected ? tagInfo.$2 : mutedColor.withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                              color: isSelected ? tagInfo.$1 : Colors.transparent,
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? tagInfo.$2 : mutedColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // 关联书籍
                    Text('关联作品 (可选)', style: TextStyle(fontSize: 12, color: mutedColor)),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '输入作品名称...',
                        hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.5), fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: TextStyle(fontSize: 13, color: textColor),
                      onChanged: (v) => selectedBook = v,
                      controller: TextEditingController(text: selectedBook),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      _confirmDelete(ctx, provider, fragment);
                      Navigator.pop(ctx);
                    },
                    child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('取消', style: TextStyle(color: mutedColor)),
                ),
                TextButton(
                  onPressed: () {
                    final content = contentCtrl.text.trim();
                    if (content.isEmpty) return;

                    if (isEditing) {
                      provider.updateFragment(
                        id: fragment.id!,
                        content: content,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        tag: selectedTag,
                        bookTitle: selectedBook.isEmpty ? null : selectedBook,
                      );
                    } else {
                      provider.addFragment(
                        content: content,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        tag: selectedTag,
                        bookTitle: selectedBook.isEmpty ? null : selectedBook,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    isEditing ? '保存' : '记录',
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, InspirationsProvider provider, InspirationItem fragment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除这条灵感碎片吗？',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteFragment(fragment.id!);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  Color bgColorOf(Color c) {
    final l = c.computeLuminance();
    return l > 0.5 ? const Color(0xFF2C2C2A) : const Color(0xFFFAFAF9);
  }
}

// ===== 搜索按钮 =====
class _SearchToggle extends StatefulWidget {
  final Color textColor;
  final Color mutedColor;
  final void Function(bool open) onToggle;
  final void Function(String query) onChanged;

  const _SearchToggle({
    required this.textColor,
    required this.mutedColor,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_SearchToggle> createState() => _SearchToggleState();
}

class _SearchToggleState extends State<_SearchToggle> {
  bool _open = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return GestureDetector(
        onTap: () {
          setState(() => _open = true);
          widget.onToggle(true);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 18, color: widget.mutedColor),
            const SizedBox(width: 4),
            Text('搜索', style: TextStyle(fontSize: 13, color: widget.mutedColor)),
          ],
        ),
      );
    }

    return SizedBox(
      width: 180,
      height: 30,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TextStyle(fontSize: 13, color: widget.textColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.mutedColor.withValues(alpha: 0.3)),
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              _ctrl.clear();
              widget.onChanged('');
              setState(() => _open = false);
              widget.onToggle(false);
            },
            child: Icon(Icons.close, size: 14, color: widget.mutedColor),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ===== 虚线边框画家 =====
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final r = BorderRadius.circular(10).toRRect(
      const Rect.fromLTWH(0, 0, 0, 0),
    );

    // Simple rect for now
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );

    _drawDashedRect(canvas, size, const Radius.circular(10), paint, dashWidth, dashSpace);
  }

  void _drawDashedRect(Canvas canvas, Size size, Radius radius, Paint paint, double dashW, double dashG) {
    final path = Path();

    // Top
    double x = radius.x;
    while (x < size.width - radius.x) {
      final end = (x + dashW).clamp(0.0, size.width - radius.x).toDouble();
      path.moveTo(x, 0); path.lineTo(end, 0);
      x = end + dashG;
    }
    // Bottom
    x = radius.x;
    while (x < size.width - radius.x) {
      final end = (x + dashW).clamp(0.0, size.width - radius.x).toDouble();
      path.moveTo(x, size.height); path.lineTo(end, size.height);
      x = end + dashG;
    }
    // Left
    double y = radius.y;
    while (y < size.height - radius.y) {
      final end = (y + dashW).clamp(0.0, size.height - radius.y).toDouble();
      path.moveTo(0, y); path.lineTo(0, end);
      y = end + dashG;
    }
    // Right
    y = radius.y;
    while (y < size.height - radius.y) {
      final end = (y + dashW).clamp(0.0, size.height - radius.y).toDouble();
      path.moveTo(size.width, y); path.lineTo(size.width, end);
      y = end + dashG;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

