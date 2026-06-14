import 'package:flutter/material.dart';
import 'package:omiku/models/manga_series.dart';

class AddSeriesDialog extends StatefulWidget {
  final Function(MangaSeries) onSave;

  const AddSeriesDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddSeriesDialogState createState() => _AddSeriesDialogState();
}

class _AddSeriesDialogState extends State<AddSeriesDialog> {
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
              ),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              TextFormField(
                controller: _coverController,
                decoration: const InputDecoration(labelText: 'Cover Path / URL *'),
                validator: (v) => v!.isEmpty ? 'Cover location required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newSeries = MangaSeries(
                id: DateTime.now().millisecondsSinceEpoch.toString(), // Quick simple ID generation
                title: _titleController.text.trim(),
                author: _authorController.text.trim().isEmpty ? 'Unknown' : _authorController.text.trim(),
                coverPath: _coverController.text.trim(),
                description: _descController.text.trim(),
              );
              widget.onSave(newSeries);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}