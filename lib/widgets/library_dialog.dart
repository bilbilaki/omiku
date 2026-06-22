import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/services/anime_manga_service.dart';

class LibraryDialog extends StatefulWidget {
  final TextEditingController seriesNameController;
  final TextEditingController descriptionController;
  final TextEditingController chapterNameController;
  final TextEditingController chapterNumController;
  final File coverImage;
  final Function(bool isNewSeries, MangaSeries? existingSeries, String? onlineCoverUrl) onDone;

  const LibraryDialog({
    required this.onDone,
    required this.coverImage,
    required this.seriesNameController,
    required this.chapterNameController,
    required this.chapterNumController,
    required this.descriptionController,
    super.key,
  });

  @override
  State<LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<LibraryDialog> {
  bool _isNewSeries = true; // Handles Choice 1 vs Choice 2
  bool _isSearchOnline = false; // Handles Manual vs Search Online

  // Choice 2: Existing Series states
  List<MangaSeries> _existingSeriesList = [];
  MangaSeries? _selectedExistingSeries;
  bool _isLoadingSeries = false;

  // Choice 1: Online Search states
  final TextEditingController _searchController = TextEditingController();
  final AnimeMangaService _mangaService = AnimeMangaService();
  bool _isLoadingSearch = false;
  String? _onlineCoverUrl;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _loadExistingSeries();
  }

  Future<void> _loadExistingSeries() async {
    setState(() => _isLoadingSeries = true);
    try {
      final list = await db.getAll<MangaSeries>();
      setState(() {
        _existingSeriesList = list;
        _isLoadingSeries = false;
      });
    } catch (e) {
      setState(() => _isLoadingSeries = false);
      debugPrint("Error loading existing library: $e");
    }
  }

  Future<void> _performOnlineSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoadingSearch = true;
      _searchError = '';
    });

    try {
      final result = await _mangaService.searchMangaDetails(query);
      if (result != null && result.data.media != null) {
        setState(() {
          // Auto-populate form fields with metadata returned from AniList
          widget.seriesNameController.text = result.data.media!.title?.english ?? 
              result.data.media!.title?.romaji ?? 
              result.data.media!.title?.native ?? '';
          
          // Clear standard HTML tags that GraphQL description strings often contain
          widget.descriptionController.text = (result.data.media!.description ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), '');

          _onlineCoverUrl = result.data.media!.coverImage?.extraLarge ?? 
              result.data.media!.coverImage?.large ?? 
              result.data.media!.coverImage?.medium;
          
          _isLoadingSearch = false;
        });
      } else {
        setState(() {
          _searchError = 'No matching manga records found.';
          _isLoadingSearch = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Lookup failed: $e';
        _isLoadingSearch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 27, 27, 27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height * 0.7,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _onlineCoverUrl != null 
                      ? NetworkImage(_onlineCoverUrl!) as ImageProvider
                      : FileImage(widget.coverImage),
                  fit: BoxFit.cover,
                  opacity: 0.12,
                ),
                borderRadius: BorderRadius.circular(20.0),
                color: const Color.fromARGB(225, 27, 27, 27),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Import Configuration',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    
                    // Mode Chooser Segmented Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.create_new_folder),
                            label: const Text('As New Series'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isNewSeries ? Colors.blueAccent : Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => setState(() => _isNewSeries = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.library_add),
                            label: const Text('Add to Existing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isNewSeries ? Colors.blueAccent : Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => setState(() => _isNewSeries = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Choice 1 View
                    if (_isNewSeries) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Manual Info'),
                            selected: !_isSearchOnline,
                            onSelected: (_) => setState(() => _isSearchOnline = false),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Search Online (AniList)'),
                            selected: _isSearchOnline,
                            onSelected: (_) => setState(() => _isSearchOnline = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isSearchOnline) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Query Online Manga Database',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: _isLoadingSearch 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.search),
                              onPressed: _isLoadingSearch ? null : _performOnlineSearch,
                            ),
                          ],
                        ),
                        if (_searchError.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(_searchError, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: widget.seriesNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Series Title',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] 
                    // Choice 2 View
                    else ...[
                      _isLoadingSeries
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<MangaSeries>(
                              dropdownColor: const Color.fromARGB(255, 30, 30, 30),
                              value: _selectedExistingSeries,
                              hint: const Text('Choose Destination Series', style: TextStyle(color: Colors.white70)),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.collections, color: Colors.white70),
                              ),
                              items: _existingSeriesList.map((series) {
                                return DropdownMenuItem<MangaSeries>(
                                  value: series,
                                  child: Text(series.title, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedExistingSeries = value),
                            ),
                    ],

                    const Divider(color: Colors.white24, height: 32),
                    const Text('Chapter Assignment Metadata', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: widget.chapterNumController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Chapter No.',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: widget.chapterNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Chapter Name / Title',
                              labelStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_isNewSeries && widget.seriesNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please specify a series title.')));
                          return;
                        }
                        if (!_isNewSeries && _selectedExistingSeries == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an existing series destination.')));
                          return;
                        }
                        if (widget.chapterNumController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter Number is required.')));
                          return;
                        }
                        widget.onDone(_isNewSeries, _selectedExistingSeries, _onlineCoverUrl);
                      },
                      child: const Text('Finalize Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}