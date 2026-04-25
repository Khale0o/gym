import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gymsaas/core/theme.dart';

/// Shimmer loading placeholder block.
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: cardDark,
      highlightColor: borderDark,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A column of shimmer blocks that mimics a loading card.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDark),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder(width: 120, height: 12),
          SizedBox(height: 10),
          ShimmerPlaceholder(height: 28),
          SizedBox(height: 8),
          ShimmerPlaceholder(width: 80, height: 10),
        ],
      ),
    );
  }
}
