class MangaPanel {
  final String id;
  final double x;      // Center X coordinate of the panel
  final double y;      // Center Y coordinate of the panel
  final double width;  // Total panel width
  final double height; // Total panel height
  final double scale;  // Dynamic target scale multiplier

  MangaPanel({
    required this.id, 
    required this.x, 
    required this.y, 
    required this.width, 
    required this.height, 
    this.scale = 2.0,
  });

  // Factory to construct instances straight out of your Python script output
  factory MangaPanel.fromJson(Map<String, dynamic> json) {
    return MangaPanel(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
    );
  }
}