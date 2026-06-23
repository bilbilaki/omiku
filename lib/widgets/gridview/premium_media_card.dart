import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omiku/widgets/gridview/media_badge.dart';
import 'package:omiku/widgets/gridview/minimal_progressbar.dart';
import 'package:omiku/widgets/gridview/universal_image_loader.dart';

/// THE COMPOSITE PREMIUM CARD WIDGET
class PremiumMediaCard extends StatefulWidget {
  final String id;
  final String title;
  final String overview;
  final String imagePath; // Can be a URL, an Asset path, or a local file path
  final String? badgeText; // e.g., "Ch. 12" or "Ep. 5"
  final double? rating; // e.g., 8.7
  final double progress; // Value between 0.0 and 1.0 (How much read/watched)
  final VoidCallback onTap;

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
  });

  @override
  State<PremiumMediaCard> createState() => _PremiumMediaCardState();
}

class _PremiumMediaCardState extends State<PremiumMediaCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Theme setup: Dark Blue and Crimson Red Accent
    final themeBgColor = const Color(0xFF0A1128).withValues(alpha: 0.7); 
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
        onLongPressStart: (_) {
          HapticFeedback.heavyImpact();
          setState(() => _isExpanded = true);
        },
        onLongPressEnd: (_) {
          setState(() => _isExpanded = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isExpanded ? accentColor.withValues(alpha: 0.4) : Colors.black38,
                blurRadius: _isExpanded ? 16 : 8,
                spreadRadius: _isExpanded ? 2 : 0,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Layer 1: Universal Image Background with local/remote system
                Positioned.fill(
                  child: UniversalImageLoader(imagePath: widget.imagePath),
                ),

                // Layer 2: Blurred Texture Overlay for Dark Theme aesthetic
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: _isExpanded ? 5 : 0, sigmaY: _isExpanded ? 5 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            themeBgColor.withValues(alpha: 0.4),
                            themeBgColor.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.5, 0.9],
                        ),
                      ),
                    ),
                  ),
                ),

                // Layer 3: Metadata Badges (Top Left/Right)
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

                // Layer 4: Information Panel (Title, Dynamic Overview, Progress)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            const SizedBox(height: 4),
                            // Animated Overview Panel
                            AnimatedCrossFade(
                              firstChild: Text(
                                widget.overview,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              secondChild: Text(
                                widget.overview,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                              ),
                              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 250),
                            ),
                          ],
                        ),
                      ),
                      // Layer 5: Minimal Progress Bar
                      MinimalProgressBar(progress: widget.progress, color: accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}