import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';

/// Breathing pulse dot used for "live" markers (next prayer, GPS status).
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    this.color,
    this.size = AppSize.pulseDot,
    this.glow = true,
  });

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
    duration: AppMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Both the platform and the in-app reduce-motion settings stop the pulse
  /// at its rest state instead of leaving a small animation running forever.
  void _syncMotion() {
    if (AppSpring.isDisabled(context)) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final reduceMotion = AppSpring.isDisabled(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion
            ? AppOpacity.none
            : AppMotion.soft.transform(_controller.value);
        final scale = AppSize.pulseScaleBase + AppSize.pulseScaleRange * t;
        return Container(
          width: widget.size * scale,
          height: widget.size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                      color: color.withValues(
                        alpha:
                            AppOpacity.pulseGlowPeak -
                            AppOpacity.pulseGlowDrop * t,
                      ),
                      blurRadius:
                          AppElevation.pulseBaseBlur +
                          AppElevation.pulseRangeBlur * t,
                      spreadRadius: AppElevation.pulseSpread,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
