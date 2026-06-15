import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omiku/models/manga_panel.dart';

class MangaReaderScreen extends StatefulWidget {
  final List<MangaPanel> detectedPanels;
  final File mangaImage;
  final VoidCallback onNextPage;
  final VoidCallback onPervPage;

  const MangaReaderScreen({
    super.key,
    required this.detectedPanels,
    required this.mangaImage,
    required this.onNextPage,
    required this.onPervPage,
  });

  @override
  MangaReaderScreenState createState() => MangaReaderScreenState();
}

class MangaReaderScreenState extends State<MangaReaderScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _cameraAnimation;

  int _currentStep = 0;
  bool _initialNavigationPending = false;

  double _currentScale = 1.0;
  double _currentX = 0.0;
  double _currentY = 0.0;
  Size _rawImageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initialNavigationPending = widget.detectedPanels.isNotEmpty;

    widget.mangaImage.readAsBytes().then((bytes) {
      decodeImageFromList(bytes).then((decoded) {
        if (!mounted) {
          return;
        }

        setState(() {
          _rawImageSize = Size(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          );
        });
        _tryInitialNavigation();
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

    _transformationController.addListener(() {
      final Matrix4 matrix = _transformationController.value;
      setState(() {
        _currentScale = matrix.getMaxScaleOnAxis();
        _currentX = matrix.getTranslation().x;
        _currentY = matrix.getTranslation().y;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryInitialNavigation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _tryInitialNavigation() {
    if (!mounted ||
        !_initialNavigationPending ||
        widget.detectedPanels.isEmpty ||
        _rawImageSize == Size.zero) {
      return;
    }

    _initialNavigationPending = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.detectedPanels.isEmpty) {
        return;
      }
      _navigateToPanel(widget.detectedPanels[_currentStep]);
    });
  }

  void _navigateToPanel(MangaPanel panel) {
    if (!mounted || _rawImageSize == Size.zero) return;

    final Size viewportSize = MediaQuery.sizeOf(context);
    final double targetScale = panel.targetScaleForViewport(
      viewportSize,
      paddingFraction: panel.isHorizontal ? 0.10 : 0.14,
    );

    final double targetX = (viewportSize.width / 2) - (panel.x * targetScale);
    final double targetY = (viewportSize.height / 2) - (panel.y * targetScale);

    final targetMatrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0)
      ..setTranslationRaw(targetX, targetY, 0.0);

    _animationController.stop();
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
    } else {
     // widget.onNextPage();
    }
  }

  void _pervStep() {
    if (_currentStep >= 1) {
      setState(() {
        _currentStep--;
      });
      _navigateToPanel(widget.detectedPanels[_currentStep]);
    } else {
     // widget.onPervPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size viewportSize = MediaQuery.sizeOf(context);
    final Size imageSize = _rawImageSize;
    final MangaPanel? activePanel = widget.detectedPanels.isNotEmpty
        ? widget.detectedPanels[_currentStep]
        : null;
    final double activePanelTargetScale = activePanel == null
        ? 0.0
        : activePanel.targetScaleForViewport(viewportSize);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.05,
            maxScale: 6.0,
            constrained: false, // <--- THE MAGIC FIX
            child: imageSize == Size.zero
                ? const SizedBox.expand()
                : SizedBox(
                    width: imageSize.width,
                    height: imageSize.height,
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.cyan, width: 3),
                            ),
                            child: Image.file(
                              widget.mangaImage,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: InternalDebugPainter(
                                widget.detectedPanels,
                                _currentStep,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
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
                        'LIVE ENGINE TELEMETRY [Panel ${_currentStep + 1}/${widget.detectedPanels.length}]',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(color: Colors.grey, height: 10),
                      Text(
                        'Device Viewport Size: ${viewportSize.width.toStringAsFixed(0)} x ${viewportSize.height.toStringAsFixed(0)}',
                        style: _debugStyle,
                      ),
                      Text(
                        'File Raw Resolution: ${_rawImageSize.width.toStringAsFixed(0)} x ${_rawImageSize.height.toStringAsFixed(0)}',
                        style: _debugStyle,
                      ),
                      Text(
                        'Viewport Scale: ${_currentScale.toStringAsFixed(2)}x (Targeting: ${activePanelTargetScale.toStringAsFixed(2)}x)',
                        style: _debugStyle,
                      ),
                      Text(
                        'Camera Position Vector: (${_currentX.toStringAsFixed(0)}, ${_currentY.toStringAsFixed(0)})',
                        style: _debugStyle,
                      ),
                      if (activePanel != null) ...[
                        const Divider(color: Colors.grey, height: 10),
                        Text(
                          'Target Panel Specs:',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '   - Global Center Coordinate: (${activePanel.x.toStringAsFixed(1)}, ${activePanel.y.toStringAsFixed(1)})',
                          style: _debugStyle,
                        ),
                        Text(
                          '   - Bounding Box: ${activePanel.width.toStringAsFixed(0)} x ${activePanel.height.toStringAsFixed(0)}',
                          style: _debugStyle,
                        ),
                        Text(
                          '   - Orientation: ${activePanel.orientationLabel}',
                          style: _debugStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        : 'Next Panel',
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

class InternalDebugPainter extends CustomPainter {
  final List<MangaPanel> panels;
  final int activeIndex;

  InternalDebugPainter(this.panels, this.activeIndex);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < panels.length; i++) {
      final panel = panels[i];
      final bool isActive = i == activeIndex;

      final paint = Paint()
        ..color = isActive
            ? Colors.amber.withAlpha(77)
            : Colors.red.withAlpha(38)
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = isActive ? Colors.amber : Colors.red
        ..strokeWidth = isActive ? 3 : 1.5
        ..style = PaintingStyle.stroke;

      final rect = panel.bounds;

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);

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
