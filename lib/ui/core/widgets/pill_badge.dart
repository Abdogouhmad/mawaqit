import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/ui/core/widgets/pulse_dot.dart';

/// Rounded status capsule with optional leading dot (design pill badges).
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    this.dotColor,
    this.onColor,
    this.background,
    this.uppercase = true,
  });

  final String label;
  final Color? dotColor;
  final Color? onColor;
  final Color? background;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = onColor ??
        (isLight
            ? scheme.primary
            : const Color(0xFF3E9B76));
    final bg = background ??
        (isLight
            ? const Color(0xFFA4F3CA).withValues(alpha: 0.5)
            : const Color(0xFF3E9B76).withValues(alpha: 0.2));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            PulseDot(color: dotColor, size: 6, glow: false),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}