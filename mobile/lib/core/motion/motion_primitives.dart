import 'package:flutter/material.dart';

/// BizSquare Motion Primitives System (Section 14)
/// Provides reusable, consistent motion primitives across all screens.
/// Enforces consistent timing (200-350ms) and Curves.easeOutCubic curves.

/// 1. PressableScale: Touch feedback micro-interaction
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 2. StateTransitionSwitcher: Consistent layout & state transitions (Section 15)
class StateTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final Object keyObject;
  final Duration duration;

  const StateTransitionSwitcher({
    super.key,
    required this.child,
    required this.keyObject,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(keyObject),
        child: child,
      ),
    );
  }
}

/// 3. AnimatedCounterText: Smooth rolling number transition
class AnimatedCounterText extends StatelessWidget {
  final int count;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const AnimatedCounterText({
    super.key,
    required this.count,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix${value.toInt()}$suffix',
          style: style,
        );
      },
    );
  }
}

/// 4. SubtlePulseGlow: Attention pulse without excessive animation
class SubtlePulseGlow extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const SubtlePulseGlow({
    super.key,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<SubtlePulseGlow> createState() => _SubtlePulseGlowState();
}

class _SubtlePulseGlowState extends State<SubtlePulseGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isEnabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SubtlePulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
