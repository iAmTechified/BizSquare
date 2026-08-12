import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BizSquareLoader extends StatefulWidget {
  final double size;
  final bool showText;
  final String? text;

  const BizSquareLoader({
    super.key,
    this.size = 44.0,
    this.showText = false,
    this.text,
  });

  @override
  State<BizSquareLoader> createState() => _BizSquareLoaderState();
}

class _BizSquareLoaderState extends State<BizSquareLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _BizSquareLogoPainter(
                progress: _controller.value,
              ),
            );
          },
        ),
        if (widget.showText) ...[
          const SizedBox(height: 10),
          Text(
            widget.text ?? 'Grow Together',
            style: AppTheme.satoshi(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _BizSquareLogoPainter extends CustomPainter {
  final double progress;

  _BizSquareLogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Glowing Ambient Halo
    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.18 + 0.08 * math.sin(progress * 2 * math.pi))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.22);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    final angle = progress * 2 * math.pi;

    // 4 Morphing Rounded Squares in Ribbon Motion
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.accentMagenta,
      AppTheme.secondaryLime,
      AppTheme.primaryBlue,
    ];

    for (int i = 0; i < 4; i++) {
      final itemAngle = angle + (i * math.pi / 2);
      final dist = radius * (0.55 + 0.15 * math.sin(angle * 2 + i));
      final itemCenter = Offset(
        center.dx + dist * math.cos(itemAngle),
        center.dy + dist * math.sin(itemAngle),
      );

      final squareSize = size.width * 0.24 * (0.85 + 0.25 * math.cos(angle + i));
      final rect = Rect.fromCenter(center: itemCenter, width: squareSize, height: squareSize);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(squareSize * 0.32));

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(itemCenter.dx, itemCenter.dy);
      canvas.rotate(itemAngle + math.pi / 4);
      canvas.translate(-itemCenter.dx, -itemCenter.dy);
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }

    // Center Interlocking Square Ring
    final centerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.30,
      height: size.width * 0.30,
    );
    final centerRRect = RRect.fromRectAndRadius(centerRect, Radius.circular(size.width * 0.09));

    final centerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryBlue,
          AppTheme.accentMagenta,
          AppTheme.secondaryLime,
        ],
        transform: GradientRotation(-angle),
      ).createShader(centerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-angle * 1.5);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRRect(centerRRect, centerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BizSquareLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
