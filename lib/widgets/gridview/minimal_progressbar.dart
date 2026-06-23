import 'package:flutter/material.dart';

class MinimalProgressBar extends StatelessWidget {
  final double progress; // Ranges from 0.0 to 1.0
  final Color color;

  const MinimalProgressBar({super.key, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      width: double.infinity,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}