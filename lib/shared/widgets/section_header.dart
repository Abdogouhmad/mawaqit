import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';

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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            SizedBox(
              width: 34,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
                child: Icon(icon, size: AppIconSize.lg, color: scheme.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description!,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
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
