import 'package:flutter/material.dart';
import 'package:gymsaas/widgets/apex_text.dart';

/// Small pill badge with background tinted to the given color.
class ApexBadge extends StatelessWidget {
  final String text;
  final Color color;

  const ApexBadge({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: ApexText(
        text,
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
