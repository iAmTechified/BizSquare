import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../data/micro_niche_taxonomy.dart';
import '../providers/taxonomy_provider.dart';

// ─── Shimmer Skeleton ─────────────────────────────────────────────────────────

class TaxonomyShimmer extends StatelessWidget {
  const TaxonomyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E2A3D) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF2A3A54) : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulates search field
          _ShimmerBox(height: 50, radius: 12, width: double.infinity),
          const SizedBox(height: 16),
          // Simulates category accordion cards
          for (int i = 0; i < 5; i++) ...[
            _ShimmerCategoryCard(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ShimmerCategoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(height: 14, width: 140, radius: 6),
                const SizedBox(height: 6),
                _ShimmerBox(height: 11, width: 90, radius: 4),
              ],
            ),
          ),
          _ShimmerBox(height: 20, width: 20, radius: 4),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class TaxonomyErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TaxonomyErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFEF4444),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load categories',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0058FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class TaxonomyEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const TaxonomyEmptyState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFF59E0B),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No categories yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The server returned no business categories.\nPlease contact support or try refreshing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0058FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wrapper ──────────────────────────────────────────────────────────────────
/// Drop-in wrapper that manages all taxonomy async states.
/// Use [builder] to render your UI once data is ready.
class TaxonomyStateWrapper extends ConsumerWidget {
  final Widget Function(List<Category> categories) builder;

  const TaxonomyStateWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(taxonomyProvider);

    return asyncCats.when(
      loading: () => const TaxonomyShimmer(),
      error: (err, _) => TaxonomyErrorState(
        message: err.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.read(taxonomyProvider.notifier).refresh(),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return TaxonomyEmptyState(
            onRetry: () => ref.read(taxonomyProvider.notifier).refresh(),
          );
        }
        return builder(categories);
      },
    );
  }
}
