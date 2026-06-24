import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omiku/utils/ext_field.dart';

class AwesomeUnifiedSearchField extends StatefulWidget {
  // External search callbacks (plug in your providers here)
  final FutureOr<void> Function(String query)? searchMovies;
  final FutureOr<void> Function(String query)? searchTv;
  final FutureOr<void> Function(String query)? searchAnime;

  // Optional advanced button (e.g., open UnifiedSearchBottomSheet)
  final VoidCallback? onAdvancedTap;
    final VoidCallback? onDownloadsTap;


  // Text field params
  final TextEditingController? controller;
  final FocusNode? focusNode;

  // Behavior
  final Duration debounce;
  final int minChars;
  final bool autofocus;

  // UI
  final String hintText;
  final EdgeInsetsGeometry padding;
  final bool showAdvancedButton;

  const AwesomeUnifiedSearchField({
    super.key,
    this.searchMovies,
    this.searchTv,
    this.searchAnime,
    this.onAdvancedTap,
    this.onDownloadsTap,
    this.controller,
    this.focusNode,
    this.debounce = const Duration(milliseconds: 300),
    this.minChars = 1,
    this.autofocus = false,
    this.hintText = 'Search Movies, TV & Anime...',
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0),
    this.showAdvancedButton = true,
  });

  @override
  State<AwesomeUnifiedSearchField> createState() =>
      _AwesomeUnifiedSearchFieldState();
}

class _AwesomeUnifiedSearchFieldState extends State<AwesomeUnifiedSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;

  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      final q = _controller.text.trim();
      if (q == _lastQuery) return;
      _lastQuery = q;
      if (q.isEmpty) {
        _clearAll();
        return;
      }
      if (q.length >= widget.minChars) {
        _performUnifiedSearch(q);
      }
    });
  }

  void _performUnifiedSearch(String query) {
    // Call all enabled targets
    widget.searchMovies?.call(query);
    widget.searchTv?.call(query);
    widget.searchAnime?.call(query);
  }

  void _clearAll() {
    widget.searchMovies?.call('');
    widget.searchTv?.call('');
    widget.searchAnime?.call('');
  }

  void _onSubmitted(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      _clearAll();
    } else {
      _performUnifiedSearch(q);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
                      Tooltip(
            message: 'Downloads',
            child: Ink(
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.12),
                shape: const CircleBorder(),
              ),
              child: IconButton(
                onPressed: widget.onDownloadsTap,
                icon: const Icon(Icons.download),
                tooltip: 'Downloads Screen',
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: extField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSubmitted,
              onChanged: (v) {
                // The extField's clear button calls onChanged('') when pressed.
                // We debounce in _onTextChanged, but this keeps external listeners possible.
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                // Keep default prefix search icon and animated clear from extField.
              ),
            ),
          ),
          if (widget.showAdvancedButton) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Advanced',
              child: Ink(
                decoration: ShapeDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha:0.12),
                  shape: const CircleBorder(),
                ),
                child: IconButton(
                  onPressed: widget.onAdvancedTap,
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filters / Advanced',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
