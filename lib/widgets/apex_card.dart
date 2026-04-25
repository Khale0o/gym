import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';

/// Luxury dark card with optional gold glow and tap support.
class ApexCard extends StatelessWidget {
  final Widget child;
  final bool glow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const ApexCard({
    super.key,
    required this.child,
    this.glow = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderDark),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: gold.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
