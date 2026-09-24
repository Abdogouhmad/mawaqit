import 'package:flutter/material.dart';

/// Breathing pulse dot used for "live" markers (next prayer, GPS status).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color, this.size = 8, this.glow = true});

  final Color? color;
  final double size;
  final bool glow;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.8 + 0.4 * t;
        return Container(
          width: widget.size * scale,
          height: widget.size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55 - 0.35 * t),
                      blurRadius: 6 + 6 * t,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
