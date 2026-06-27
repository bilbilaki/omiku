import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'radial_action_overlay.dart';
import 'media_badge.dart';
import 'minimal_progressbar.dart';
import 'universal_image_loader.dart';

class PremiumMediaCard extends StatefulWidget {
  final String id;
  final String title;
  final String overview;
  final String imagePath;
  final String? badgeText;
  final double? rating;
  final double progress;
  final VoidCallback onTap;

  // New features (disabled by default)
  final bool enableActionMenu;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onRefetch;

  const PremiumMediaCard({
    super.key,
    required this.id,
    required this.title,
    required this.overview,
    required this.imagePath,
    this.badgeText,
    this.rating,
    this.progress = 0.0,
    required this.onTap,
    this.enableActionMenu = false,
    this.onEdit,
    this.onDelete,
    this.onRename,
    this.onRefetch,
  });

  @override
  State<PremiumMediaCard> createState() => _PremiumMediaCardState();
}

class _PremiumMediaCardState extends State<PremiumMediaCard> {
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  
  // High-performance State Management variables
  final ValueNotifier<Offset> _dragOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _releaseNotifier = ValueNotifier<bool>(false);
  Offset _touchStartPoint = Offset.zero;

  void _showRadialMenu(BuildContext context, Offset globalTouchPoint) {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final cardPosition = renderBox.localToGlobal(Offset.zero);
    final cardSize = renderBox.size;

    _dragOffsetNotifier.value = Offset.zero;
    _releaseNotifier.value = false;
    _touchStartPoint = globalTouchPoint;

    final List<ActionTarget> targetActions = [
      if (widget.onRename != null)
        const ActionTarget(
          label: "Rename",
          icon: Icons.drive_file_rename_outline,
          color: Colors.purple,
          relativeOffset: Offset(-105, -105),
        ),
      if (widget.onRefetch != null)
        const ActionTarget(
          label: "Refetch",
          icon: Icons.refresh,
          color: Colors.teal,
          relativeOffset: Offset(105, -105),
        ),
      if (widget.onEdit != null)
        const ActionTarget(
          label: "Edit",
          icon: Icons.edit_note,
          color: Colors.indigo,
          relativeOffset: Offset(-115, 25),
        ),
      if (widget.onDelete != null)
        const ActionTarget(
          label: "Delete",
          icon: Icons.delete_forever,
          color: Colors.redAccent,
          relativeOffset: Offset(115, 25),
        ),
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => RadialActionOverlay(
        touchStartPoint: _touchStartPoint,
        dragOffsetNotifier: _dragOffsetNotifier,
        triggerReleaseNotifier: _releaseNotifier,
        actions: targetActions,
        cardSize: cardSize,
        cardPosition: cardPosition,
        cardPreview: _buildCardContent(isOverlayMode: true),
        onActionSelected: (action) {
          _closeRadialMenu();
          switch (action.label) {
            case "Rename":
              widget.onRename?.call();
              break;
            case "Refetch":
              widget.onRefetch?.call();
              break;
            case "Edit":
              widget.onEdit?.call();
              break;
            case "Delete":
              widget.onDelete?.call();
              break;
          }
        },
        onCancel: () {
          _closeRadialMenu();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeRadialMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBgColor = const Color(0xFF0A1128).withOpacity(0.7);
    final accentColor = const Color(0xFFD90429);

    return Hero(
      tag: 'media_card_${widget.id}',
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        return Material(type: MaterialType.transparency, child: toHeroContext.widget);
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        // Setup dynamic dragging metrics based on gesture updates
        onLongPressStart: (details) {
          HapticFeedback.heavyImpact();
          setState(() {
            _isExpanded = true;
          });
          if (widget.enableActionMenu) {
            _showRadialMenu(context, details.globalPosition);
          }
        },
        onLongPressMoveUpdate: (details) {
          if (widget.enableActionMenu) {
            _dragOffsetNotifier.value = details.globalPosition - _touchStartPoint;
          }
        },
        onLongPressEnd: (_) {
          if (widget.enableActionMenu) {
            _releaseNotifier.value = true;
          } else {
            setState(() {
              _isExpanded = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isExpanded ? accentColor.withOpacity(0.4) : Colors.black38,
                blurRadius: _isExpanded ? 24 : 8,
                spreadRadius: _isExpanded ? 3 : 0,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent({bool isOverlayMode = false}) {
    final themeBgColor = const Color(0xFF0A1128).withOpacity(0.7);
    final accentColor = const Color(0xFFD90429);
    final showLongOverview = _isExpanded || isOverlayMode;

    return Stack(
      children: [
        Positioned.fill(
          child: UniversalImageLoader(imagePath: widget.imagePath),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: showLongOverview ? 12.0 : 0.0,
              sigmaY: showLongOverview ? 12.0 : 0.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    themeBgColor.withOpacity(0.5),
                    themeBgColor.withOpacity(showLongOverview ? 0.98 : 0.95),
                  ],
                  stops: const [0.0, 0.45, 0.9],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.badgeText != null) MediaBadge(text: widget.badgeText!, color: accentColor),
              if (widget.rating != null) RatingIndicator(rating: widget.rating!),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    AnimatedCrossFade(
                      firstChild: Text(
                        widget.overview,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondChild: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            widget.overview,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      crossFadeState: showLongOverview ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              MinimalProgressBar(progress: widget.progress, color: accentColor),
            ],
          ),
        ),
      ],
    );
  }
}