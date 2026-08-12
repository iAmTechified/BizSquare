import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';

class HomeSkeletons extends StatelessWidget {
  const HomeSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Skeleton
            Row(
              children: [
                const ShimmerCircle(size: 48),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 12, width: 90, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(height: 18, width: 140, borderRadius: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Setup Banner Skeleton
            const ShimmerBox(height: 120, width: double.infinity, borderRadius: 16),
            const SizedBox(height: 16),

            // Contact Gain Hero Card Skeleton
            const ShimmerBox(height: 190, width: double.infinity, borderRadius: 20),
            const SizedBox(height: 16),

            // Horizontal Contacts Carousel Skeleton
            Row(
              children: const [
                ShimmerBox(height: 150, width: 180, borderRadius: 16),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBox(height: 150, width: double.infinity, borderRadius: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Spotlight Skeleton
            const ShimmerBox(height: 180, width: double.infinity, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}
