import 'package:flutter/material.dart';
import 'package:omiku/models/manga_panel.dart';
import 'dart:io';

class MangaReaderScreen extends StatefulWidget {
  final List<MangaPanel> detectedPanels;
  final File mangaImage;

  const MangaReaderScreen({
    Key? key,
    required this.detectedPanels,
    required this.mangaImage,
  }) : super(key: key);

  @override
  _MangaReaderScreenState createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _cameraAnimation;

  int _currentStep = 0;

  // Real-time tracking values for the cockpit display
  double _currentScale = 1.0;
  double _currentX = 0.0;
  double _currentY = 0.0;
  Size _rawImageSize = Size.zero;

  @override
  void initState() {
    super.initState();

    // Read the true resolution of the file
    widget.mangaImage.readAsBytes().then((bytes) {
      decodeImageFromList(bytes).then((decoded) {
        setState(() {
          _rawImageSize = Size(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          );
        });
      });
    });

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..addListener(() {
          if (_cameraAnimation != null) {
            _transformationController.value = _cameraAnimation!.value;
          }
        });

    // Track user pan/zoom movements in real-time
    _transformationController.addListener(() {
      final Matrix4 matrix = _transformationController.value;
      setState(() {
        _currentScale = matrix.getMaxScaleOnAxis();
        _currentX = matrix.getTranslation().x;
        _currentY = matrix.getTranslation().y;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.detectedPanels.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _navigateToPanel(widget.detectedPanels[_currentStep]);
        });
      }
    });
  }

  void _navigateToPanel(MangaPanel panel) {
    if (!mounted) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Pivot centering math matrix targeting coordinates cleanly
    final double targetX = (screenWidth*0.9) - (panel.x * panel.scale);
    final double targetY = (screenHeight/1.4) - (panel.y * panel.scale);

    final targetMatrix = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(panel.scale);

    _cameraAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _animationController.forward(from: 0.0);
  }

  void _nextStep() {
    if (_currentStep < widget.detectedPanels.length - 1) {
      setState(() {
        _currentStep++;
      });
      _navigateToPanel(widget.detectedPanels[_currentStep]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = _rawImageSize;
    final MangaPanel? activePanel = widget.detectedPanels.isNotEmpty
        ? widget.detectedPanels[_currentStep]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24), // Blueprint Dark Grey
      body: Stack(
        children: [
          // --- THE INFINITE CANVAS ---
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale:
                0.05, // Allow zooming way out to see the whole blueprint layout
            maxScale: 6.0,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  // The actual manga image constrained to screen width
                  Container(
                    width: screenSize.width,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.cyan,
                        width: 3,
                      ), // Visual marker for image boundaries
                    ),
                    child: Image.file(widget.mangaImage, fit: BoxFit.cover),
                  ),

                  // Dynamic Overlay Debug Painter drawn on top of the image container space
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: InternalDebugPainter(
                          widget.detectedPanels,
                          screenSize.width,
                          _currentStep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- FIXED SCREEN CENTER CROSSHAIR ---
          // This crosshair shows exactly where the middle of your phone screen is.
          // The targeted panel's center should land exactly inside this crosshair.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Center(
                  child: Container(width: 4, height: 4, color: Colors.amber),
                ),
              ),
            ),
          ),

          // --- THE COCKPIT INSTRUMENT PANEL (TOP OVERLAY) ---
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: IgnorePointer(
              child: Card(
                color: Colors.black.withAlpha(150),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "📊 LIVE ENGINE TELEMETRY [Panel ${_currentStep + 1}/${widget.detectedPanels.length}]",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(color: Colors.grey, height: 10),
                      Text(
                        "📱 Device Viewport Size: ${screenSize.width.toStringAsFixed(0)} x ${screenSize.height.toStringAsFixed(0)}",
                        style: _debugStyle,
                      ),
                      Text(
                        "🖼️ File Raw Resolution: ${_rawImageSize.width.toStringAsFixed(0)} x ${_rawImageSize.height.toStringAsFixed(0)}",
                        style: _debugStyle,
                      ),
                      Text(
                        "🔎 Viewport Scale: ${_currentScale.toStringAsFixed(2)}x (Targeting: ${activePanel?.scale ?? 0.0}x)",
                        style: _debugStyle,
                      ),
                      Text(
                        "📍 Camera Position Vector: (${_currentX.toStringAsFixed(0)}, ${_currentY.toStringAsFixed(0)})",
                        style: _debugStyle,
                      ),
                      if (activePanel != null) ...[
                        const Divider(color: Colors.grey, height: 10),
                        Text(
                          "🎯 Target Panel Specs:",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "   • Global Center Coordinate: (${activePanel.x.toStringAsFixed(1)}, ${activePanel.y.toStringAsFixed(1)})",
                          style: _debugStyle,
                        ),
                        Text(
                          "   • Scaled Box Bounding Box: ${activePanel.width.toStringAsFixed(0)} x ${activePanel.height.toStringAsFixed(0)}",
                          style: _debugStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- CONTROL FOOTER BUTTONS ---
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  hoverColor: Colors.black54,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                FloatingActionButton.extended(
                  onPressed: _nextStep,
                  label: Text(
                    _currentStep == widget.detectedPanels.length - 1
                        ? 'End of Page'
                        : 'Next Panel ⏭️',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _debugStyle => const TextStyle(
    color: Colors.white70,
    fontFamily: 'monospace',
    fontSize: 11,
  );
}

// Tailored internal painter that highlights the ACTIVE targeted panel step differently
class InternalDebugPainter extends CustomPainter {
  final List<MangaPanel> panels;
  final double renderWidth;
  final int activeIndex;

  InternalDebugPainter(this.panels, this.renderWidth, this.activeIndex);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < panels.length; i++) {
      final panel = panels[i];
      final bool isActive = (i == activeIndex);

      final paint = Paint()
        ..color = isActive
            ? Colors.amber.withOpacity(0.3)
            : Colors.red.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = isActive ? Colors.amber : Colors.red
        ..strokeWidth = isActive ? 3 : 1.5
        ..style = PaintingStyle.stroke;

      // Box geometry calculations based directly on parsed model variables
      final left = panel.x - (panel.width / 2);
      final top = panel.y - (panel.height / 2);
      final rect = Rect.fromLTWH(left, top, panel.width, panel.height);

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);

      // Draw center cross target on the layout structure itself
      canvas.drawCircle(
        Offset(panel.x, panel.y),
        4,
        Paint()..color = isActive ? Colors.amber : Colors.red,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'P$i',
          style: TextStyle(
            color: isActive ? Colors.yellow : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
