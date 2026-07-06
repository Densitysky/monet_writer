import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/providers/inspirations_provider.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/utils/inspiration_tag_colors.dart';
import 'package:monet_writer/utils/app_strings.dart';
import 'package:monet_writer/widgets/theme/app_card.dart';
import 'package:monet_writer/widgets/theme/app_divider.dart';

/// 移动端灵感碎片页面
class InspirationsPage extends StatefulWidget {
  const InspirationsPage({super.key});

  @override
  State<InspirationsPage> createState() => _InspirationsPageState();
}

class _InspirationsPageState extends State<InspirationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspirationsProvider>().loadFragments();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 仅碎片列表和标签变化时重建，避免搜索/编辑触发整页刷新
    final fragments = context.select<InspirationsProvider, List<InspirationItem>>(
      (p) => List.unmodifiable(p.filteredFragments),
    );
    final activeTag = context.select<InspirationsProvider, String>((p) => p.activeTag);
    final provider = context.read<InspirationsProvider>();
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final isPaper = themeProvider.themeStyle == AppThemeStyle.paper;
    final textColor = theme.colorScheme.onSurface;
    final accentColor = theme.colorScheme.primary;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);
    final bgColor = theme.scaffoldBackgroundColor;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(AppStrings.inspirations),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签筛选
          _buildTagBar(provider, textColor, accentColor, mutedColor, isDark, isNeumorphic),
          // 内容区
          Expanded(
            child: fragments.isEmpty
                ? _buildEmptyState(textColor, hintColor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: fragments.length,
                    itemBuilder: (context, index) {
                      return _buildFragmentCard(
                        fragments[index],
                        provider,
                        textColor,
                        mutedColor,
                        hintColor,
                        isDark,
                        isNeumorphic,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordSheet(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagBar(InspirationsProvider provider, Color textColor, Color accentColor, Color mutedColor, bool isDark, bool isNeumorphic) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: InspirationsProvider.availableTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tag = InspirationsProvider.availableTags[index];
          final isActive = provider.activeTag == tag;
          final chip = GestureDetector(
            onTap: () => provider.setActiveTag(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isActive ? accentColor : mutedColor.withValues(alpha: 0.2),
                ),
                color: isActive ? accentColor : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? (accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                      : mutedColor,
                ),
              ),
            ),
          );
          // 柔和模式下 active 标签用 AppCard 包裹，做出轻微浮雕
          if (isNeumorphic && isActive) {
            return AppCard(padding: EdgeInsets.zero, child: chip);
          }
          return chip;
        },
      ),
    );
  }

  Widget _buildFragmentCard(
    InspirationItem fragment,
    InspirationsProvider provider,
    Color textColor,
    Color mutedColor,
    Color hintColor,
    bool isDark,
    bool isNeumorphic,
  ) {
    final tagInfo = getInspirationTagColor(fragment.tag);
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主内容
        Text(
          fragment.content,
          style: TextStyle(
            fontSize: 14,
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
            style: TextStyle(fontSize: 12, color: mutedColor, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        // 底部
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tagInfo.$1,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fragment.tag,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tagInfo.$2),
              ),
            ),
            if (fragment.bookTitle != null) ...[
              const SizedBox(width: 6),
              Text(fragment.bookTitle!, style: TextStyle(fontSize: 11, color: mutedColor)),
            ],
            const Spacer(),
            Text(
              _formatTime(fragment.updateTime),
              style: TextStyle(fontSize: 11, color: hintColor),
            ),
          ],
        ),
      ],
    );

    if (isNeumorphic) {
      return AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        onTap: () => _showRecordSheet(context, provider, fragment: fragment),
        child: cardContent,
      );
    }

    return GestureDetector(
      onTap: () => _showRecordSheet(context, provider, fragment: fragment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: textColor.withValues(alpha: 0.08)),
        ),
        child: cardContent,
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color hintColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, size: 48, color: hintColor),
          const SizedBox(height: 12),
          Text(AppStrings.noInspirations, style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text(AppStrings.noInspirationsHint, style: TextStyle(fontSize: 13, color: hintColor)),
        ],
      ),
    );
  }

  // ===== 底部记录面板 =====
  void _showRecordSheet(
    BuildContext context,
    InspirationsProvider provider, {
    InspirationItem? fragment,
  }) {
    final isEditing = fragment != null;
    final contentCtrl = TextEditingController(text: fragment?.content ?? '');
    final noteCtrl = TextEditingController(text: fragment?.note ?? '');
    String selectedTag = fragment?.tag ?? '其他';
    String selectedBook = fragment?.bookTitle ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? AppStrings.editInspiration : AppStrings.recordInspiration,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 内容
                    TextField(
                      controller: contentCtrl,
                      autofocus: !isEditing,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(ctx).colorScheme.onSurface,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.writeInspiration,
                        hintStyle: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 备注
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: AppStrings.supplementaryNote,
                        hintStyle: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.25),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 标签
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: InspirationsProvider.availableTags
                          .where((t) => t != '全部')
                          .map((tag) {
                        final isSelected = selectedTag == tag;
                        final tagInfo = getInspirationTagColor(tag);
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedTag = tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected ? tagInfo.$2 : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                                width: isSelected ? 1.5 : 1,
                              ),
                              color: isSelected ? tagInfo.$1 : Colors.transparent,
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? tagInfo.$2 : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // 关联书籍
                    TextField(
                      decoration: InputDecoration(
                        hintText: AppStrings.linkToBook,
                        hintStyle: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.25),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurface),
                      onChanged: (v) => selectedBook = v,
                      controller: TextEditingController(text: selectedBook),
                    ),
                    const SizedBox(height: 16),

                    // 操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isEditing)
                          TextButton(
                            onPressed: () {
                              provider.deleteFragment(fragment.id!);
                              Navigator.pop(ctx);
                            },
                            child: const Text(AppStrings.delete, style: TextStyle(color: Colors.redAccent)),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            '取消',
                            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
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
                          child: Text(isEditing ? AppStrings.save : AppStrings.record),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSearch(BuildContext context, InspirationsProvider provider) {
    showSearch(
      context: context,
      delegate: _InspirationSearchDelegate(provider),
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
}

/// 搜索代理
class _InspirationSearchDelegate extends SearchDelegate<String> {
  final InspirationsProvider provider;

  _InspirationSearchDelegate(this.provider) {
    provider.setSearchQuery('');
  }

  @override
  String? get searchFieldLabel => '搜索灵感碎片...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            provider.setSearchQuery('');
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        provider.setSearchQuery('');
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    provider.setSearchQuery(query);
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    provider.setSearchQuery(query);
    return _buildResultsList(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final fragments = provider.filteredFragments;
    if (fragments.isEmpty) {
      return Center(
        child: Text(
          '没有找到匹配的灵感',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fragments.length,
      itemBuilder: (context, index) {
        final f = fragments[index];
        return ListTile(
          title: Text(f.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(f.tag, style: const TextStyle(fontSize: 12)),
          onTap: () => close(context, f.content),
        );
      },
    );
  }
}

