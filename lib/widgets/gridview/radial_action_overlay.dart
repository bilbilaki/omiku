import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActionTarget {
  final String label;
  final IconData icon;
  final Color color;
  final Offset relativeOffset;

  const ActionTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.relativeOffset,
  });
}

class RadialActionOverlay extends StatefulWidget {
  final Offset touchStartPoint;
  final ValueNotifier<Offset> dragOffsetNotifier;
  final ValueNotifier<bool> triggerReleaseNotifier;
  final List<ActionTarget> actions;
  final ValueChanged<ActionTarget> onActionSelected;
  final VoidCallback onCancel;
  final Widget cardPreview;
  final Size cardSize;
  final Offset cardPosition;

  const RadialActionOverlay({
    super.key,
    required this.touchStartPoint,
    required this.dragOffsetNotifier,
    required this.triggerReleaseNotifier,
    required this.actions,
    required this.onActionSelected,
    required this.onCancel,
    required this.cardPreview,
    required this.cardSize,
    required this.cardPosition,
  });

  @override
  State<RadialActionOverlay> createState() => _RadialActionOverlayState();
}

class _RadialActionOverlayState extends State<RadialActionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _fadeInController;
  late Animation<double> _scaleAnimation;
  String? _hoveredActionLabel;
  final double _targetRadius = 55.0; // Dynamic action collision zone

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutBack,
    );
    _fadeInController.forward();

    widget.dragOffsetNotifier.addListener(_onDragUpdate);
    widget.triggerReleaseNotifier.addListener(_onRelease);
  }

  @override
  void dispose() {
    widget.dragOffsetNotifier.removeListener(_onDragUpdate);
    widget.triggerReleaseNotifier.removeListener(_onRelease);
    _fadeInController.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    final currentOffset = widget.dragOffsetNotifier.value;
    String? currentHover;

    for (var action in widget.actions) {
      final distance = (currentOffset - action.relativeOffset).distance;
      if (distance <= _targetRadius) {
        currentHover = action.label;
        break;
      }
    }

    if (_hoveredActionLabel != currentHover) {
      HapticFeedback.lightImpact();
      setState(() {
        _hoveredActionLabel = currentHover;
      });
    }
  }

  void _onRelease() {
    if (widget.triggerReleaseNotifier.value) {
      final currentOffset = widget.dragOffsetNotifier.value;
      ActionTarget? selectedAction;

      for (var action in widget.actions) {
        final distance = (currentOffset - action.relativeOffset).distance;
        if (distance <= _targetRadius) {
          selectedAction = action;
          break;
        }
      }

      if (selectedAction != null) {
        HapticFeedback.heavyImpact();
        widget.onActionSelected(selectedAction);
      } else {
        widget.onCancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double maxDragDistance = 130.0;

    return Stack(
      children: [
        // Premium Blurred Background Overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(_scaleAnimation.value * 0.75),
              );
            },
          ),
        ),

        // Hero Card Clone in Long Mode Preview (Zoomed & Scaled)
        Positioned(
          left: widget.cardPosition.dx,
          top: widget.cardPosition.dy,
          width: widget.cardSize.width,
          height: widget.cardSize.height,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.05).animate(
              CurvedAnimation(parent: _fadeInController, curve: Curves.easeOutCubic),
            ),
            child: widget.cardPreview,
          ),
        ),

        // Interactive Radial Interface Actions
        Positioned(
          left: widget.touchStartPoint.dx,
          top: widget.touchStartPoint.dy,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Render action nodes radially
                    ...widget.actions.map((action) {
                      final isHovered = _hoveredActionLabel == action.label;
                      return Positioned(
                        left: action.relativeOffset.dx - 45,
                        top: action.relativeOffset.dy - 45,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: isHovered ? 1.25 : 1.0,
                          curve: Curves.easeOutBack,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isHovered ? action.color : const Color(0xFF1E1E24),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isHovered
                                          ? action.color.withOpacity(0.5)
                                          : Colors.black45,
                                      blurRadius: isHovered ? 20 : 10,
                                      spreadRadius: isHovered ? 4 : 1,
                                    )
                                  ],
                                  border: Border.all(
                                    color: isHovered ? Colors.white : Colors.white12,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(action.icon, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 6),
                              Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    action.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),

                    // The Draggable Floater Puck
                    ValueListenableBuilder<Offset>(
                      valueListenable: widget.dragOffsetNotifier,
                      builder: (context, offset, child) {
                        // Math limits the puck from moving too far from its original center
                        double distance = offset.distance;
                        Offset clampedOffset = offset;
                        if (distance > maxDragDistance) {
                          clampedOffset = Offset.fromDirection(offset.direction, maxDragDistance);
                        }

                        return Transform.translate(
                          offset: clampedOffset,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: const Icon(Icons.drag_indicator, color: Colors.white, size: 24),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}