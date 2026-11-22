import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Label/value list row (icon · label — value), used by the OTA "version
/// details" card. [highlight] promotes the value to the primary accent.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
          ],
          // Both sides are flexible: at 200% text (and in AR, where the value
          // can be a long localized date) a fixed intrinsic value pushes the
          // row past the card instead of wrapping.
          Flexible(child: UiText(label, color: scheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: UiText(
              value,
              textAlign: TextAlign.end,
              fontWeight: FontWeight.w700,
              color: highlight ? scheme.primary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
