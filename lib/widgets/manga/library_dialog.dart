import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/services/contentApi/anime_manga_service.dart';

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
  bool _isNewSeries = true; // Handles New Series vs Existing Series tabs
  bool _isSearchOnline = false; // Handles Manual Metadata vs Online Search toggle

  // Choice 2: Existing Series states
  List<MangaSeries> _existingSeriesList = [];
  MangaSeries? _selectedExistingSeries;
  bool _isLoadingSeries = false;

  // Choice 1: Online Search states
  final TextEditingController _onlineSearchController = TextEditingController();
  List<MangaMedia> _onlineSearchResults = [];
  bool _isSearchingOnline = false;
  String? _onlineCoverUrl;
  MangaMedia? _selectedOnlineManga;

  @override
  void initState() {
    super.initState();
    _loadExistingSeries();
  }

  Future<void> _loadExistingSeries() async {
    if (!mounted) return;
    setState(() => _isLoadingSeries = true);
    try {
      final list = await db.getAll<MangaSeries>();
      if (mounted) {
        setState(() {
          _existingSeriesList = list;
          _isLoadingSeries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSeries = false);
      }
    }
  }

  Future<void> _performOnlineSearch() async {
    final queryText = _onlineSearchController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a query to search.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingOnline = true;
      _onlineSearchResults = [];
      _selectedOnlineManga = null;
    });

    try {
      final service = AnimeMangaService();
      final result = await service.searchMangaDetails(queryText);
      if (mounted) {
        setState(() {
          _onlineSearchResults = [result.data.media];
        });
      }
    } catch (e) {
      debugPrint('Online manga search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching manga: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingOnline = false;
        });
      }
    }
  }

  void _applySelectedOnlineManga(MangaMedia manga) {
    setState(() {
      _selectedOnlineManga = manga;
      widget.seriesNameController.text = manga.title.romaji ?? '';
      widget.descriptionController.text = _cleanHtmlDescription(manga.description ?? '');
      _onlineCoverUrl = manga.coverImage.extraLarge ?? manga.coverImage.large ?? manga.coverImage.medium;
      _isSearchOnline = false; // Auto return to input review
    });
  }

  String _cleanHtmlDescription(String html) {
    // Basic regex pattern to wipe out HTML tags from description texts returned by AniList
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 24 + keyboardInset,
          ),
          child: Material(
            color: Colors.transparent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 500,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1527), Color(0xFF03071E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark_add, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Configure Manga Import',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Organize your digital book archive',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Top Tab Selection (New Series vs Existing Series)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSegmentButton(
                                text: 'Create New',
                                isActive: _isNewSeries,
                                onTap: () => setState(() => _isNewSeries = true),
                              ),
                            ),
                            Expanded(
                              child: _buildSegmentButton(
                                text: 'Add to Existing',
                                isActive: !_isNewSeries,
                                onTap: () {
                                  if (_existingSeriesList.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No existing series found. Please import as a new series.')),
                                    );
                                    return;
                                  }
                                  setState(() => _isNewSeries = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Main Scrollable Area containing Form Details
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isNewSeries) ...[
                              // Sub-tab toggler for Manual Input vs Online Metadata Fetch
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactChoice(
                                      title: 'Manual Setup',
                                      icon: Icons.edit_note,
                                      isSelected: !_isSearchOnline,
                                      onTap: () => setState(() => _isSearchOnline = false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildCompactChoice(
                                      title: 'Online Metadata',
                                      icon: Icons.travel_explore,
                                      isSelected: _isSearchOnline,
                                      onTap: () => setState(() => _isSearchOnline = true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_isSearchOnline) ...[
                                // Online metadata search input field
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _onlineSearchController,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        onSubmitted: (_) => _performOnlineSearch(),
                                        decoration: InputDecoration(
                                          hintText: 'Search AniList (e.g., Chainsaw Man)',
                                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                                          filled: true,
                                          fillColor: Colors.black45,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Colors.amber),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _performOnlineSearch,
                                      child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Search Results Viewport
                                if (_isSearchingOnline) ...[
                                  const Center(
                                    //: EdgeInsets.symmetric(vertical: 24),
                                    child: CircularProgressIndicator(color: Colors.amber),
                                  ),
                                ] else if (_onlineSearchResults.isNotEmpty) ...[
                                  const Text(
                                    'Select Manga Connection:',
                                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _onlineSearchResults.length,
                                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final manga = _onlineSearchResults[index];
                                        final coverUrl = manga.coverImage.medium ?? manga.coverImage.large;
                                        return InkWell(
                                          onTap: () => _applySelectedOnlineManga(manga),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _selectedOnlineManga?.id == manga.id
                                                    ? Colors.amber
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (coverUrl != null)
                                                    Image.network(coverUrl, fit: BoxFit.cover)
                                                  else
                                                    Container(color: Colors.grey[900]),
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                                      color: Colors.black87,
                                                      child: Text(
                                                        manga.title.romaji,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ] else ...[
                                  const Center(
                                 //   padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'Search for books to populate metadata automatically.',
                                      style: TextStyle(color: Colors.white30, fontSize: 11),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                              ],

                              if (!_isSearchOnline) ...[
                                // Title textfield
                                _buildInputField(
                                  label: 'Manga Title',
                                  controller: widget.seriesNameController,
                                  hint: 'Enter series name...',
                                ),
                                const SizedBox(height: 14),

                                // Description textfield
                                _buildInputField(
                                  label: 'Series Synopsis / Description',
                                  controller: widget.descriptionController,
                                  hint: 'Enter series details...',
                                  maxLines: 3,
                                ),
                              ],
                            ] else ...[
                              // Existing Series list display
                              const Text(
                                'Select Target Series:',
                                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _isLoadingSeries
                                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                                  : Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: _existingSeriesList.length,
                                        itemBuilder: (context, index) {
                                          final item = _existingSeriesList[index];
                                          final isSelected = _selectedExistingSeries?.seriesId == item.seriesId;

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedExistingSeries = item;
                                                // Pre-fill chapter values based on series title config
                                                widget.seriesNameController.text = item.title;
                                                widget.descriptionController.text = item.description;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.amber.withValues(alpha: 0.12) : Colors.black45,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.03),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: SizedBox(
                                                      width: 40,
                                                      height: 50,
                                                      child: item.onlineCoverUrl != null
                                                          ? Image.network(item.onlineCoverUrl!, fit: BoxFit.cover)
                                                          : Image.file(File(item.coverPath), fit: BoxFit.cover),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          'ID: ${item.seriesId.substring(0, 8)}...',
                                                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    const Icon(Icons.check_circle, color: Colors.amber, size: 20),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],

                            const SizedBox(height: 18),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),

                            // Chapter Config Header
                            const Text(
                              'Chapter Configuration',
                              style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Row for Chapter Number and Chapter Title
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildInputField(
                                    label: 'Chapter #',
                                    controller: widget.chapterNumController,
                                    hint: 'e.g. 1.0',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 5,
                                  child: _buildInputField(
                                    label: 'Chapter Name',
                                    controller: widget.chapterNameController,
                                    hint: 'Optional (e.g., Prologue)',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Preview Cover thumbnail widget
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 60,
                                      height: 80,
                                      child: _onlineCoverUrl != null
                                          ? Image.network(_onlineCoverUrl!, fit: BoxFit.cover)
                                          : Image.file(widget.coverImage, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Cover Art Image',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _onlineCoverUrl != null
                                              ? 'Using online media resource covers'
                                              : 'Local image extracted from first page',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        if (_selectedOnlineManga != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                            ),
                                            child: const Text(
                                              'Linked to AniList Metadata',
                                              style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Actions Area (Confirm / Cancel)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  if (_isNewSeries && widget.seriesNameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please specify a series title.')),
                                    );
                                    return;
                                  }
                                  if (!_isNewSeries && _selectedExistingSeries == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select an existing target series.')),
                                    );
                                    return;
                                  }
                                  if (widget.chapterNumController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Chapter Number is required.')),
                                    );
                                    return;
                                  }
                                  if (double.tryParse(widget.chapterNumController.text.trim()) == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please specify a valid numeric chapter number.')),
                                    );
                                    return;
                                  }

                                  widget.onDone(_isNewSeries, _selectedExistingSeries, _onlineCoverUrl);
                                },
                                child: const Text(
                                  'Finalize Import',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSegmentButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChoice({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withValues(alpha: 0.08) : Colors.black12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.03),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.amber : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            filled: true,
            fillColor: Colors.black45,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
          ),
        ),
      ],
    );
  }
}


class LibraryPage extends StatefulWidget {
  final TextEditingController seriesNameController;
  final TextEditingController descriptionController;
  final TextEditingController chapterNameController;
  final TextEditingController chapterNumController;
  final File coverImage;
  final Function(bool isNewSeries, MangaSeries? existingSeries, String? onlineCoverUrl) onDone;

  const LibraryPage({
    required this.onDone,
    required this.coverImage,
    required this.seriesNameController,
    required this.chapterNameController,
    required this.chapterNumController,
    required this.descriptionController,
    super.key,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isNewSeries = true;
  bool _isSearchOnline = false;

  List<MangaSeries> _existingSeriesList = [];
  MangaSeries? _selectedExistingSeries;
  bool _isLoadingSeries = false;

  final TextEditingController _onlineSearchController = TextEditingController();
  List<MangaMedia> _onlineSearchResults = [];
  bool _isSearchingOnline = false;
  String? _onlineCoverUrl;
  MangaMedia? _selectedOnlineManga;

  @override
  void initState() {
    super.initState();
    _loadExistingSeries();
  }

  Future<void> _loadExistingSeries() async {
    if (!mounted) return;
    setState(() => _isLoadingSeries = true);
    try {
      final list = await db.getAll<MangaSeries>();
      if (mounted) {
        setState(() {
          _existingSeriesList = list;
          _isLoadingSeries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSeries = false);
      }
    }
  }

  Future<void> _performOnlineSearch() async {
    final queryText = _onlineSearchController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a query to search.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingOnline = true;
      _onlineSearchResults = [];
      _selectedOnlineManga = null;
    });

    try {
      final service = AnimeMangaService();
      final result = await service.searchMangaDetails(queryText);
      if (mounted) {
        setState(() {
          _onlineSearchResults.add(result.data.media);
        });
      }
    } catch (e) {
      debugPrint('Online manga search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching manga: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingOnline = false);
      }
    }
  }

  void _applySelectedOnlineManga(MangaMedia manga) {
    setState(() {
      _selectedOnlineManga = manga;
      widget.seriesNameController.text = manga.title.romaji ?? '';
      widget.descriptionController.text = _cleanHtmlDescription(manga.description ?? '');
      _onlineCoverUrl = manga.coverImage.extraLarge ?? manga.coverImage.large ?? manga.coverImage.medium;
      _isSearchOnline = false;
    });
  }

  String _cleanHtmlDescription(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03071E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1527), Color(0xFF03071E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Dedicated Top Bar Layout
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_add, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Configure Manga Import',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Organize your digital book archive',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                floating: true,
              ),

              // Form Elements
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Primary Navigation Option Tab Selection
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              text: 'Create New',
                              isActive: _isNewSeries,
                              onTap: () => setState(() => _isNewSeries = true),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              text: 'Add to Existing',
                              isActive: !_isNewSeries,
                              onTap: () {
                                if (_existingSeriesList.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No existing series found. Please import as a new series.')),
                                  );
                                  return;
                                }
                                setState(() => _isNewSeries = false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isNewSeries) ...[
                      // Manual setup / Online metadata selection
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactChoice(
                              title: 'Manual Setup',
                              icon: Icons.edit_note,
                              isSelected: !_isSearchOnline,
                              onTap: () => setState(() => _isSearchOnline = false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCompactChoice(
                              title: 'Online Metadata',
                              icon: Icons.travel_explore,
                              isSelected: _isSearchOnline,
                              onTap: () => setState(() => _isSearchOnline = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_isSearchOnline) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _onlineSearchController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                onSubmitted: (_) => _performOnlineSearch(),
                                decoration: InputDecoration(
                                  hintText: 'Search AniList (e.g., Chainsaw Man)',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                                  filled: true,
                                  fillColor: Colors.black45,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.amber),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _performOnlineSearch,
                              child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isSearchingOnline) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator(color: Colors.amber)),
                          ),
                        ] else if (_onlineSearchResults.isNotEmpty) ...[
                          const Text(
                            'Select Manga Connection:',
                            style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              scrollDirection: Axis.horizontal,
                              itemCount: _onlineSearchResults.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final manga = _onlineSearchResults[index];
                                final coverUrl = manga.coverImage.medium ?? manga.coverImage.large;
                                return InkWell(
                                  onTap: () => _applySelectedOnlineManga(manga),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedOnlineManga?.id == manga.id ? Colors.amber : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (coverUrl != null) Image.network(coverUrl, fit: BoxFit.cover) else Container(color: Colors.grey[900]),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                              color: Colors.black87,
                                              child: Text(
                                                manga.title.romaji,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Search for books to populate metadata automatically.',
                              style: TextStyle(color: Colors.white30, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      if (!_isSearchOnline) ...[
                        _buildInputField(
                          label: 'Manga Title',
                          controller: widget.seriesNameController,
                          hint: 'Enter series name...',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Series Synopsis / Description',
                          controller: widget.descriptionController,
                          hint: 'Enter series details...',
                          maxLines: 3,
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Select Target Series:',
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingSeries
                          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _existingSeriesList.length,
                              itemBuilder: (context, index) {
                                final item = _existingSeriesList[index];
                                final isSelected = _selectedExistingSeries?.seriesId == item.seriesId;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedExistingSeries = item;
                                      widget.seriesNameController.text = item.title;
                                      widget.descriptionController.text = item.description;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.amber.withValues(alpha: 0.12) : Colors.black45,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.03),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: SizedBox(
                                            width: 40,
                                            height: 50,
                                            child: item.onlineCoverUrl != null
                                                ? Image.network(item.onlineCoverUrl!, fit: BoxFit.cover)
                                                : Image.file(File(item.coverPath), fit: BoxFit.cover),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: ${item.seriesId.substring(0, 8)}...',
                                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected) const Icon(Icons.check_circle, color: Colors.amber, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    const Text(
                      'Chapter Configuration',
                      style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildInputField(
                            label: 'Chapter #',
                            controller: widget.chapterNumController,
                            hint: 'e.g. 1.0',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 5,
                          child: _buildInputField(
                            label: 'Chapter Name',
                            controller: widget.chapterNameController,
                            hint: 'Optional (e.g., Prologue)',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 80,
                              child: _onlineCoverUrl != null
                                  ? Image.network(_onlineCoverUrl!, fit: BoxFit.cover)
                                  : Image.file(widget.coverImage, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cover Art Image',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _onlineCoverUrl != null ? 'Using online media resource covers' : 'Local image extracted from first page',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                if (_selectedOnlineManga != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'Linked to AniList Metadata',
                                      style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Gives scrolling clearance above bottom navigation action layout bar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sticky confirmation bar pinned seamlessly at the base
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF03071E),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_isNewSeries && widget.seriesNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please specify a series title.')),
                      );
                      return;
                    }
                    if (!_isNewSeries && _selectedExistingSeries == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an existing target series.')),
                      );
                      return;
                    }
                    if (widget.chapterNumController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chapter Number is required.')),
                      );
                      return;
                    }
                    if (double.tryParse(widget.chapterNumController.text.trim()) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please specify a valid numeric chapter number.')),
                      );
                      return;
                    }

                    widget.onDone(_isNewSeries, _selectedExistingSeries, _onlineCoverUrl);
                  },
                  child: const Text(
                    'Finalize Import',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChoice({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withValues(alpha: 0.08) : Colors.black12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.03),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.amber : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            filled: true,
            fillColor: Colors.black45,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
          ),
        ),
      ],
    );
  }
}