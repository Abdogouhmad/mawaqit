import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
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
          Expanded(
            child: UiText(
              label,
              type: UiTextType.bodyMedium,
              color: scheme.onSurfaceVariant,
            ),
          ),
          UiText(
            value,
            type: UiTextType.bodyMedium,
            fontWeight: FontWeight.w700,
            color: highlight ? scheme.primary : scheme.onSurface,
          ),
        ],
      ),
    );
  }
}
