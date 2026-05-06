import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';

/// Standard dark card with optional brand glow and tap support.
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
        decoration: ApexDecorations.card(
          radius: borderRadius,
          glow: glow,
        ),
        child: child,
      ),
    );
  }
}
