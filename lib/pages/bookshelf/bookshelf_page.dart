import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/services/database_service.dart';
import 'package:monet_writer/pages/writing/writing_page.dart';
import 'package:monet_writer/widgets/monet_book_cover.dart';
import 'package:monet_writer/pages/bookshelf/components/book_edit_dialog.dart';
import 'package:monet_writer/pages/bookshelf/components/empty_view.dart';
import 'package:monet_writer/pages/mobile/components/mobile_scanner_page.dart';
import 'package:monet_writer/utils/monet_animations.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  late Stream<List<Book>> _booksStream;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initBooksStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initBooksStream() {
    final isar = DatabaseService().isar;
    _booksStream = isar.books
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    return books.where((b) =>
      b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (b.authorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  void _startSearch() => setState(() => _isSearching = true);
  void _stopSearch() => setState(() { _isSearching = false; _searchQuery = ''; _searchController.clear(); });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isSearching ? null : FloatingActionButton(
        onPressed: () => _showBookEditPanel(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Book>>(
          stream: _booksStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allBooks = snapshot.data!;
            final books = _filterBooks(allBooks);

            if (books.isEmpty && _searchQuery.isNotEmpty) {
              return _buildSearchEmpty();
            }
            if (books.isEmpty) {
              return EmptyView(onCreate: () => _showBookEditPanel(context));
            }

            return Column(
              children: [
                _buildAppBar(books.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      const SizedBox(height: 8),
                      _buildHeroCard(books.first),
                      _buildSectionTitle(books.length),
                      ...books.skip(1).map((b) => _buildBookTile(b)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: _isSearching
        ? Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '搜索书名或作者...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch),
            ],
          )
        : Row(
            children: [
              const Expanded(child: Text('我的书架', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
              IconButton(icon: Icon(Icons.qr_code_scanner, size: 20, color: Theme.of(context).colorScheme.outline), tooltip: '局域网同步', onPressed: () { Navigator.push(context, MonetPageRoute(builder: (_) => const MobileScannerPage())); }),
              IconButton(icon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.outline), onPressed: _startSearch),
            ],
          ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('没有找到「$_searchQuery」相关的书籍', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Book book) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MonetBookCover(book: book, width: 56, height: 76),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('最近阅读', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: primary)),
                      const SizedBox(height: 4),
                      Text(book.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(DateFormat('yyyy/MM/dd').format(book.updatedAt), style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                      const SizedBox(height: 2),
                      Text('更新: ${_fmtWords(book.wordCount)}', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => _openBook(book),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('继续写作', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('其他作品', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildBookTile(Book book) {
    final theme = Theme.of(context);
    final desc = book.description != null && book.description!.isNotEmpty ? book.description! : '暂无简介';

    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: MonetBookCover(book: book, width: 44, height: 60),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_fmtWords(book.wordCount), style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                      const SizedBox(width: 8),
                      Text('\u00B7', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline.withValues(alpha: 0.4))),
                      const SizedBox(width: 8),
                      Text(DateFormat('M月d日').format(book.updatedAt), style: TextStyle(fontSize: 12, color: theme.colorScheme.outline.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert, color: theme.colorScheme.outline.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  void _openBook(Book book) {
    Navigator.push(context, MonetPageRoute(builder: (_) => WritingPage(book: book, initialChapterIndex: -1)));
  }

  void _showBookEditPanel(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const BookEditPanel());
  }

  String _fmtWords(int w) {
    if (w >= 10000) return '${(w / 10000).toStringAsFixed(1)} 万字';
    return '$w 字';
  }
}
