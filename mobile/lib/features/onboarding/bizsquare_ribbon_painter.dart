import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Interactive flowing geometric BizSquare ribbon made from rounded square nodes
/// connected by smooth Bezier curves that passes across slides.
class BizSquareRibbonPainter extends CustomPainter {
  final double slideProgress; // 0.0 to 2.0
  final double wavePhase;     // continuous ambient loop phase 0.0 to 1.0
  final bool isDark;

  BizSquareRibbonPainter({
    required this.slideProgress,
    required this.wavePhase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Calculate dynamic anchor control points based on current slide & continuous wave
    final waveOffset = math.sin(wavePhase * 2 * math.pi) * 14.0;
    final waveCos = math.cos(wavePhase * 2 * math.pi) * 12.0;

    // Perspective depth shifting according to horizontal slide progress
    final p0 = Offset(-w * 0.2 + (slideProgress * -40), h * 0.30 + waveOffset);
    final p1 = Offset(w * 0.28, h * 0.22 - waveOffset * 0.8);
    final p2 = Offset(w * 0.68, h * 0.44 + waveCos);
    final p3 = Offset(w * 1.25 + ((2.0 - slideProgress) * 40), h * 0.28 - waveOffset);

    // 1. Draw Broad Flowing Ribbon Stream
    final path = Path();
    path.moveTo(p0.dx, p0.dy);
    path.cubicTo(
      p1.dx - 30, p1.dy + 40,
      p1.dx + 40, p1.dy - 30,
      p2.dx, p2.dy,
    );
    path.cubicTo(
      p2.dx + 50, p2.dy + 30,
      p3.dx - 60, p3.dy - 40,
      p3.dx, p3.dy,
    );

    // Glowing Ambient Aura behind Ribbon
    final auraPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryBlue.withValues(alpha: isDark ? 0.35 : 0.22),
          AppTheme.accentMagenta.withValues(alpha: isDark ? 0.30 : 0.18),
          AppTheme.secondaryLime.withValues(alpha: isDark ? 0.25 : 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawPath(path, auraPaint);

    // Main Sharp High-Gloss Ribbon Line
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppTheme.primaryBlue,
          AppTheme.accentMagenta,
          AppTheme.secondaryLime,
          AppTheme.primaryBlue,
        ],
        stops: [0.0, 0.45, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, ribbonPaint);

    // 2. Geometric Rounded Square Nodes along the ribbon path
    final nodePoints = [
      Offset(w * 0.18, h * 0.26 + waveOffset * 0.5),
      Offset(w * 0.48, h * 0.34 - waveCos * 0.6),
      Offset(w * 0.82, h * 0.38 + waveOffset * 0.7),
    ];

    final nodeColors = [
      AppTheme.primaryBlue,
      AppTheme.accentMagenta,
      AppTheme.secondaryLime,
    ];

    for (int i = 0; i < nodePoints.length; i++) {
      final node = nodePoints[i];
      final nodeAngle = (slideProgress * math.pi * 0.8) + (wavePhase * 2 * math.pi) + (i * 0.9);
      final nodeScale = 1.0 + 0.18 * math.sin(wavePhase * 2 * math.pi + i);
      final squareSize = 26.0 * nodeScale;

      canvas.save();
      canvas.translate(node.dx, node.dy);
      canvas.rotate(nodeAngle);

      // Node shadow
      final shadowRect = Rect.fromCenter(center: const Offset(0, 3), width: squareSize, height: squareSize);
      final shadowRRect = RRect.fromRectAndRadius(shadowRect, const Radius.circular(8));
      canvas.drawRRect(
        shadowRRect,
        Paint()
          ..color = nodeColors[i].withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Node surface with high saturation
      final rect = Rect.fromCenter(center: Offset.zero, width: squareSize, height: squareSize);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(
        rrect,
        Paint()..color = nodeColors[i],
      );

      // Inner white glossy diamond accent
      final innerRect = Rect.fromCenter(center: Offset.zero, width: squareSize * 0.38, height: squareSize * 0.38);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BizSquareRibbonPainter oldDelegate) {
    return oldDelegate.slideProgress != slideProgress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isDark != isDark;
  }
}
