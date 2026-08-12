import 'package:flutter/material.dart';

class HomeSkeletons extends StatefulWidget {
  const HomeSkeletons({super.key});

  @override
  State<HomeSkeletons> createState() => _HomeSkeletonsState();
}

class _HomeSkeletonsState extends State<HomeSkeletons> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({required double height, double width = double.infinity, double radius = 12}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            children: [
              _buildShimmerBox(height: 48, width: 48, radius: 24),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(height: 12, width: 90, radius: 4),
                  const SizedBox(height: 6),
                  _buildShimmerBox(height: 18, width: 140, radius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Setup Banner Skeleton
          _buildShimmerBox(height: 130, radius: 16),
          const SizedBox(height: 20),

          // Contact Gain Hero Card Skeleton
          _buildShimmerBox(height: 200, radius: 20),
          const SizedBox(height: 20),

          // Horizontal Contacts Carousel Skeleton
          Row(
            children: [
              _buildShimmerBox(height: 160, width: 200, radius: 16),
              const SizedBox(width: 12),
              _buildShimmerBox(height: 160, width: 200, radius: 16),
            ],
          ),
          const SizedBox(height: 20),

          // Spotlight Skeleton
          _buildShimmerBox(height: 180, radius: 20),
        ],
      ),
    );
  }
}
