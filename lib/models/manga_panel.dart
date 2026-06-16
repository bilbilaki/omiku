import 'dart:math' as math;
import 'dart:ui';

class MangaPanel {
   String id;
   double x; // Center X coordinate of the panel
   double y; // Center Y coordinate of the panel
   double width; // Total panel width
   double height; // Total panel height
   double scale; // Optional manual zoom bias multiplier

  MangaPanel({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.scale = 1.0,
  });

  bool get isHorizontal => width >= height;

  bool get isVertical => height > width;

  String get orientationLabel {
    if (isHorizontal && !isVertical) {
      return 'horizontal';
    }
    if (isVertical && !isHorizontal) {
      return 'vertical';
    }
    return 'square';
  }

  Rect get bounds =>
      Rect.fromLTWH(x - (width / 2), y - (height / 2), width, height);

  double targetScaleForViewport(
    Size viewport, {
    double paddingFraction = 0.12,
    double minScale = 0.05,
    double maxScale = 6.0,
  }) {
     double safePanelWidth = math.max(width, 1.0);
     double safePanelHeight = math.max(height, 1.0);
     double safeViewportWidth = math.max(viewport.width, 1.0);
     double safeViewportHeight = math.max(viewport.height, 1.0);

     double clampedPadding = paddingFraction.clamp(0.0, 0.45);
     double usableWidth = safeViewportWidth * (1.0 - clampedPadding);
     double usableHeight = safeViewportHeight * (1.0 - clampedPadding);

     double fitScale = math.min(
      usableWidth / safePanelWidth,
      usableHeight / safePanelHeight,
    );

     double orientationBias = isHorizontal
        ? 1.10
        : isVertical
        ? 0.95
        : 1.0;

     double targetScale = fitScale * orientationBias * scale;

    return targetScale.clamp(minScale, maxScale).toDouble();
  }

  // Factory to construct instances straight out of your Python script output
  factory MangaPanel.fromJson(Map<String, dynamic> json) {
    return MangaPanel(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
   // Added toJson method for MangaPanel
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'scale': scale,
    };
  }
}
