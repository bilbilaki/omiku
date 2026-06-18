import 'package:flutter/material.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:provider/provider.dart';

class ChapterPageOrganizerScreen extends StatefulWidget {
  final String seriesId;
  final String chapterId;

  const ChapterPageOrganizerScreen({super.key, required this.seriesId, required this.chapterId});

  @override
  State<ChapterPageOrganizerScreen> createState() => _ChapterPageOrganizerScreenState();
}

class _ChapterPageOrganizerScreenState extends State<ChapterPageOrganizerScreen> {
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<MangaStore>(context);
    final chapter = store.getChapterByID(widget.chapterId);

    if (chapter == null) return const Scaffold(body: Center(child: Text("Error locating chapter")));

    return Scaffold(
      appBar: AppBar(title: Text("Organize Pages - Ch ${chapter.chapterNumber}")),
      body: ReorderableListView.builder(
        itemCount: chapter.pagesData.length,
        itemBuilder: (context, index) {
          final page = chapter.pagesData[index];
          return ListTile(
            key: ValueKey(page.pageId),
            leading: Text("Page ${index + 1}"),
            title: Text("ID: ${page.pageId}"),
            trailing: const Icon(Icons.drag_handle),
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          
          final List<ChapterPage> items = List.from(chapter.pagesData);
          final ChapterPage removed = items.removeAt(oldIndex);
          items.insert(newIndex, removed);

          // Update Disk State Instantly via Store Mutator
          store.reorderChapterPages(widget.seriesId, widget.chapterId, items);
        },
      ),
    );
  }
}