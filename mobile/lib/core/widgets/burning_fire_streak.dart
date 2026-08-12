import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BurningFireStreak extends StatefulWidget {
  final int streakDays;
  final double size;
  final bool compact;
  final VoidCallback? onTap;

  const BurningFireStreak({
    super.key,
    this.streakDays = 7,
    this.size = 28.0,
    this.compact = false,
    this.onTap,
  });

  @override
  State<BurningFireStreak> createState() => _BurningFireStreakState();
}

class _BurningFireStreakState extends State<BurningFireStreak> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentMagenta.withValues(alpha: 0.16),
              const Color(0xFFFF5500).withValues(alpha: 0.12),
              AppTheme.secondaryLime.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentMagenta.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentMagenta.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _BurningFlamePainter(progress: _controller.value),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.streakDays}D STREAK',
              style: AppTheme.satoshi(
                fontSize: widget.compact ? 10.5 : 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.accentMagenta,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurningFlamePainter extends CustomPainter {
  final double progress;

  _BurningFlamePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.55);

    // Heatwave Glow Aura
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5500).withValues(alpha: 0.35 + 0.15 * math.sin(progress * 2 * math.pi))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.3);
    canvas.drawCircle(center, w * 0.38, glowPaint);

    final angle = progress * 2 * math.pi;

    // Dancing Outer Flame Path (Magenta to Electric Orange)
    final outerFlame = Path();
    final fX1 = w * 0.5 + 4 * math.sin(angle);
    final fY1 = h * 0.05 + 3 * math.cos(angle);

    outerFlame.moveTo(w * 0.5, h * 0.95);
    outerFlame.cubicTo(
      w * 0.15, h * 0.85,
      w * 0.10, h * 0.45,
      w * 0.35, h * 0.30,
    );
    outerFlame.cubicTo(
      w * 0.40, h * 0.15,
      fX1 - 5, fY1 + 10,
      fX1, fY1,
    );
    outerFlame.cubicTo(
      fX1 + 8, fY1 + 15,
      w * 0.85, h * 0.35,
      w * 0.90, h * 0.65,
    );
    outerFlame.cubicTo(
      w * 0.90, h * 0.85,
      w * 0.70, h * 0.95,
      w * 0.5, h * 0.95,
    );

    final outerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppTheme.accentMagenta,
          Color(0xFFFF5500),
          Color(0xFFFFCC00),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(outerFlame, outerPaint);

    // Dancing Inner Core Flame (Electric Lime to Yellow)
    final innerFlame = Path();
    final iX = w * 0.5 + 2 * math.sin(angle * 1.5);
    final iY = h * 0.35 + 2 * math.cos(angle * 1.5);

    innerFlame.moveTo(w * 0.5, h * 0.90);
    innerFlame.cubicTo(
      w * 0.30, h * 0.80,
      w * 0.30, h * 0.55,
      iX, iY,
    );
    innerFlame.cubicTo(
      w * 0.70, h * 0.55,
      w * 0.70, h * 0.80,
      w * 0.5, h * 0.90,
    );

    final innerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFCC00),
          AppTheme.secondaryLime,
          Colors.white,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(innerFlame, innerPaint);

    // Rising Spark Embers
    for (int i = 0; i < 3; i++) {
      final sparkProgress = (progress + i * 0.33) % 1.0;
      final sparkX = w * (0.35 + 0.3 * math.sin(sparkProgress * 2 * math.pi + i));
      final sparkY = h * (0.60 - sparkProgress * 0.55);
      final sparkRadius = 1.6 * (1.0 - sparkProgress);

      if (sparkRadius > 0.4) {
        canvas.drawCircle(
          Offset(sparkX, sparkY),
          sparkRadius,
          Paint()..color = (i % 2 == 0 ? AppTheme.secondaryLime : AppTheme.accentMagenta).withValues(alpha: 0.9 * (1.0 - sparkProgress)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurningFlamePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
