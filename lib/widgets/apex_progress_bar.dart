import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';

/// Animated progress bar with gold gradient fill.
class ApexProgressBar extends StatefulWidget {
  final double value;
  final double max;
  final Color color;
  final double height;

  const ApexProgressBar({
    super.key,
    required this.value,
    required this.max,
    this.color = gold,
    this.height = 5,
  });

  @override
  State<ApexProgressBar> createState() => _ApexProgressBarState();
}

class _ApexProgressBarState extends State<ApexProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: _ratio).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  double get _ratio => widget.max > 0
      ? (widget.value / widget.max).clamp(0.0, 1.0)
      : 0.0;

  @override
  void didUpdateWidget(covariant ApexProgressBar old) {
    super.didUpdateWidget(old);
    _anim = Tween<double>(begin: _anim.value, end: _ratio).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(widget.height),
        ),
        child: FractionallySizedBox(
          widthFactor: _anim.value,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height),
              gradient: LinearGradient(
                colors: [widget.color, goldLight],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
