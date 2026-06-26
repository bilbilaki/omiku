import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/utils/ex_ap_color.dart'; 

class EmbyLibrarySettingsPage extends ConsumerWidget {
  const EmbyLibrarySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Libraries'),
      ),
      body: StreamBuilder<List<LibraryConfig>>(
        stream: dbService.watchLibraries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final libraries = snapshot.data ?? [];

          if (libraries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  const Text('No media libraries configured yet.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddLibraryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Media Library'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: libraries.length + 1,
            itemBuilder: (context, index) {
              if (index == libraries.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddLibraryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Media Library'),
                  ),
                );
              }

              final library = libraries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Icon(_getIconForType(library.contentType), color: AppColors.accentColor),
                  title: Text(library.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Type: ${library.contentType.name.toUpperCase()} • ${library.folderPaths.length} folders'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, library),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      key: ValueKey(library.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text('Physical Paths:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          ...library.folderPaths.map((path) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_open, size: 16, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(path, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(LibraryContentType type) {
    switch (type) {
      case LibraryContentType.movie: return Icons.movie_creation_outlined;
      case LibraryContentType.tvShow: return Icons.tv_outlined;
      case LibraryContentType.manga: return Icons.book_outlined;
      case LibraryContentType.mixed: return Icons.folder_zip_outlined;
    }
  }

  void _confirmDelete(BuildContext context, LibraryConfig library) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${library.displayName}?'),
        content: const Text('This will remove the library collection reference from your app navigation. Your physical files will remain completely untouched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await db.deleteLibrary(library.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddLibraryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddLibraryForm(onSave: (config) async {
        await db.saveLibrary(config);
      }),
    );
  }
}

/// The stateful interactive sheet to create/edit library config paths
class _AddLibraryForm extends StatefulWidget {
  final Function(LibraryConfig) onSave;
  const _AddLibraryForm({required this.onSave});

  @override
  State<_AddLibraryForm> createState() => _AddLibraryFormState();
}

class _AddLibraryFormState extends State<_AddLibraryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LibraryContentType _selectedType = LibraryContentType.movie;
  final List<String> _paths = [];

  void _pickDirectory() async {
    // Uses file_picker package to fetch system directory path securely
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      if (!_paths.contains(selectedDirectory)) {
        setState(() {
          _paths.add(selectedDirectory);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Media Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Content Type Selection
              DropdownButtonFormField<LibraryContentType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                items: LibraryContentType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // Display Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display Name', hintText: 'e.g., Anime Collections, 4K Movies', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please input a display name' : null,
              ),
              const SizedBox(height: 20),

              // Dynamic Path Management Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Folders / Storage Paths', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _pickDirectory, icon: const Icon(Icons.add_circle_outline), label: const Text('Add Folder')),
                ],
              ),
              const SizedBox(height: 8),

              if (_paths.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Must specify at least one folder path to aggregate media files from.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),

              ..._paths.map((path) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.withValues(alpha: 0.05),
                    elevation: 0,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder, color: Colors.amber),
                      title: Text(path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _paths.remove(path)),
                      ),
                    ),
                  )),

              const SizedBox(height: 30),

              // Form Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_paths.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one physical file path.')));
                          return;
                        }
                        
                        final newConfig = LibraryConfig(
                          displayName: _nameController.text.trim(),
                          contentType: _selectedType,
                          folderPaths: _paths,
                        );
                        
                        widget.onSave(newConfig);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Ok'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}