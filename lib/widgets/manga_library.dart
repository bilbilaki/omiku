import 'package:flutter/material.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to changes inside your store automatically
    final store = context.watch<MangaStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Manga Library"),
        actions: [
          IconButton(
            icon: Icon(store.darkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => store.toggleDarkMode(),
          )
        ],
      ),
      body: store.library.isEmpty
          ? const Center(child: Text("Your collection is empty!"))
          : ListView.builder(
              itemCount: store.library.length,
              itemBuilder: (context, index) {
                final manga = store.library[index];
                return ListTile(
                  title: Text(manga.title),
                  subtitle: Text("Last page read: ${manga.progress.lastReadPage}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.menu_book),
                    onPressed: () {
                      // Simulate reading progress update
                      context.read<MangaStore>().updateReadingProgress(
                        manga.id,
                        manga.chapters.isNotEmpty ? manga.chapters.first.id : "ch-1",
                        42, // updates and saves page 42 instantly
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}