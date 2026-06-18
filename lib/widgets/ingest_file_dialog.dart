import 'package:flutter/material.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:provider/provider.dart';

class IngestFileDialog extends StatefulWidget {
  final String detectedFileName; // e.g., "One_Piece_Ch_1050.pdf"

  const IngestFileDialog({super.key, required this.detectedFileName});

  @override
  State<IngestFileDialog> createState() => _IngestFileDialogState();
}

class _IngestFileDialogState extends State<IngestFileDialog> {
  final _formKey = GlobalKey<FormState>();
  
  bool _createNewSeries = false;
  String? _selectedSeriesId;
  
  // New Series Fields
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  
  // Chapter Customization Fields
  final _chapterNumController = TextEditingController();
  final _chapterTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate fields from the filename to save user time
    _chapterTitleController.text = widget.detectedFileName.replaceAll(RegExp(r'\.(pdf|epub)$'), '');
    _chapterNumController.text = "1.0";
  }

  @override
  Widget build(BuildContext context) {
    final mangaStore = Provider.of<MangaStore>(context);
    final existingLibrary = mangaStore.library;

    return AlertDialog(
      title: const Text("Import New Document"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Target Selection Toggle
              DropdownButtonFormField<String>(
                initialValue: _createNewSeries ? "__NEW__" : _selectedSeriesId,
                decoration: const InputDecoration(labelText: "Add to Series"),
                items: [
                  if (existingLibrary.isNotEmpty)
                    ...existingLibrary.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.title),
                        )),
                  const DropdownMenuItem(
                    value: "__NEW__",
                    child: Text("+ Create New Series Container"),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val == "__NEW__") {
                      _createNewSeries = true;
                      _selectedSeriesId = null;
                    } else {
                      _createNewSeries = false;
                      _selectedSeriesId = val;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dynamic Input Fields based on targeting choice
              if (_createNewSeries) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Series Title *"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: "Author (Optional)"),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const Text("Chapter Details", style: TextStyle(fontWeight: FontWeight.bold)),
              
              TextFormField(
                controller: _chapterNumController,
                decoration: const InputDecoration(labelText: "Chapter Number (e.g. 12.5)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse(v ?? '') == null ? "Enter a valid number" : null,
              ),
              TextFormField(
                controller: _chapterTitleController,
                decoration: const InputDecoration(labelText: "Chapter Name/Subtitle"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), // Cancel Returns Null safely
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Pack all collected configuration into a map result
              Navigator.pop(context, {
                "createNewSeries": _createNewSeries,
                "seriesId": _selectedSeriesId,
                "seriesTitle": _titleController.text.trim(),
                "seriesAuthor": _authorController.text.trim(),
                "chapterNumber": double.parse(_chapterNumController.text),
                "chapterTitle": _chapterTitleController.text.trim(),
              });
            }
          },
          child: const Text("Import File"),
        ),
      ],
    );
  }
}