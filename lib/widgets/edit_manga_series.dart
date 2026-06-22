import 'package:flutter/material.dart';
import 'package:omiku/models/models.dart';

class EditMangaSeries extends StatefulWidget {
  final MangaSeries mangaSeries;

  const EditMangaSeries({super.key, required this.mangaSeries});

  @override
  _EditMangaSeriesState createState() => _EditMangaSeriesState();
}

class _EditMangaSeriesState extends State<EditMangaSeries> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _coverController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Manga Series'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Manga Title *'),
                validator: (v) => v!.isEmpty ? 'Title required' : null,
                initialValue: widget.mangaSeries.title
              ),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
                initialValue: widget.mangaSeries.author,
              ),
              TextFormField(
                controller: _coverController,
                decoration: const InputDecoration(labelText: 'Cover Path / URL *'),
                validator: (v) => v!.isEmpty ? 'Cover location required' : null,
                initialValue: widget.mangaSeries.coverPath,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                initialValue: widget.mangaSeries.description,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            //     MangaSeries ms= widget._mangaStore.  

            // if (_formKey.currentState!.validate()) {
            //   final newSeries = MangaSeries(
            //     id: seriesId,
            //     title: _titleController.text.trim(),
            //     // author: _authorController.text.trim().isEmpty ? 'Unknown' : _authorController.text.trim(),
            //     coverPath: "",
            //     // description: _descController.text.trim(),
            //   );
            //   widget.mangaSeries(newSeries);
            //   Navigator.pop(context);
            // }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}