import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:monet_writer/models/book/book.dart';
import 'package:monet_writer/providers/theme_provider.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/utils/monet_animations.dart';

import 'components/empty_view.dart';
import 'components/book_card.dart';
import 'components/hero_book_card.dart';
import 'components/book_edit_dialog.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  late Stream<List<Book>> _booksStream;

  @override
  void initState() {
    super.initState();
    _initBooksStream();
  }

  void _initBooksStream() {
    final isar = DatabaseService().isar;
    _booksStream = isar.books
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isNeumorphic = themeProvider.themeStyle == AppThemeStyle.neumorphic;
    final isParchment = themeProvider.themeStyle == AppThemeStyle.parchment;

    return Scaffold(
      appBar: isNeumorphic || isParchment
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 24),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-3, -3), blurRadius: 8),
                        BoxShadow(color: Color(0xFFC5CEDC), offset: Offset(3, 3), blurRadius: 14),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text('我的书架',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                          onPressed: () => _showSearch(context, []),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : AppBar(
              title: const Text('我的书架'),
              centerTitle: false,
              actions: [
                IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context, [])),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookEditPanel(context),
        label: const Text('新建书籍'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Book>>(
        stream: _booksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final books = snapshot.data!;
          if (books.isEmpty) {
            return EmptyView(onCreate: () => _showBookEditPanel(context));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HeroBookCard(
                  book: books.first,
                ),
              ),
              if (books.length > 1)
                SliverToBoxAdapter(
                  child: FadeSlideEntrance(
                    delayMs: 120,
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '其他作品',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.outline
                      ),
                    ),
                  ),
                  ),
                ),
              if (books.length > 1)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final book = books[index + 1];
                      return FadeSlideEntrance(
                        delayMs: 200 + index * 60,
                        child: BookCard(book: book),
                      );
                    },
                    childCount: books.length - 1,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSearch(BuildContext context, List<Book> allBooks) {
    showSearch(
      context: context,
      delegate: _BookSearchDelegate(allBooks),
    );
  }

  void _showBookEditPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookEditPanel(),
    );
  }
}

class _BookSearchDelegate extends SearchDelegate<Book?> {
  final List<Book> allBooks;
  _BookSearchDelegate(this.allBooks);

  @override
  String get searchFieldLabel => '搜索书籍...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResult(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResult(context);

  Widget _buildSearchResult(BuildContext context) {
    final results = query.isEmpty
        ? allBooks
        : allBooks.where((b) => b.title.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return Center(child: Text('没有找到相关书籍', style: TextStyle(color: Theme.of(context).colorScheme.outline)));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = results[index];
        return ListTile(
          leading: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
          title: Text(book.title),
          subtitle: Text('更新于 ${book.updatedAt != null ? DateFormat('M月d日 HH:mm').format(book.updatedAt!) : '-'}'),
          onTap: () => close(context, book),
        );
      },
    );
  }
}
