import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Quiet group header: a small accent icon chip, an uppercase letterspaced
/// label and an optional caption describing what the section controls.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.description,
    this.trailing,
    this.icon,
  });

  final String label;
  final String? description;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerIcon = icon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (headerIcon != null) ...[
            IconBadge(
              icon: headerIcon,
              size: 34,
              iconSize: AppIconSize.lg,
              color: scheme.primary.withValues(alpha: 0.08),
              foregroundColor: scheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  label.toUpperCase(),
                  type: UiTextType.labelSmall,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  UiText(
                    description!,
                    type: UiTextType.labelMedium,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
