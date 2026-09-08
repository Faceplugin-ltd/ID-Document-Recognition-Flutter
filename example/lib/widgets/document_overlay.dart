import 'package:flutter/material.dart';

import '../core/utils/result_parser.dart';
import '../app/theme.dart';

class DocumentOverlay extends StatelessWidget {
  const DocumentOverlay({
    super.key,
    required this.corners,
    required this.locked,
  });

  final List<Point> corners;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QuadPainter(
        corners: corners,
        color: locked ? AppColors.accent : const Color(0xFF60A5FA),
        strokeWidth: locked ? 8 : 5,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter({
    required this.corners,
    required this.color,
    required this.strokeWidth,
  });

  final List<Point> corners;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4) return;
    final path = Path()
      ..moveTo(corners[0].x, corners[0].y)
      ..lineTo(corners[1].x, corners[1].y)
      ..lineTo(corners[2].x, corners[2].y)
      ..lineTo(corners[3].x, corners[3].y)
      ..close();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
