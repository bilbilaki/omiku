import 'package:flutter/material.dart';
import 'package:omiku/models/models.dart';

class PanelDebugPainter extends CustomPainter {
  final List<MangaPanel> panels;
  final double imageWidth;
  final double imageHeight;

  PanelDebugPainter(this.panels, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withAlpha(77)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (int i = 0; i < panels.length; i++) {
      final panel = panels[i];

      final left = (panel.x - panel.width / 2) * scaleX;
      final top = (panel.y - panel.height / 2) * scaleY;
      final width = panel.width * scaleX;
      final height = panel.height * scaleY;

      final rect = Rect.fromLTWH(left, top, width, height);

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(color: Colors.yellow, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
