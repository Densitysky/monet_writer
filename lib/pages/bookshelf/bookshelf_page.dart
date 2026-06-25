import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:monet_writer/models/book.dart';
import 'package:monet_writer/services/database_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的书架'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
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
              if (books.length > 1)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final book = books[index + 1];
                      return BookCard(book: book);
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

  void _showBookEditPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookEditPanel(),
    );
  }
}
