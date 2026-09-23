import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/theme/tokens.dart';

/// Settings list tile: leading icon in a soft circle, title + subtitle,
/// and a trailing widget (chevron / switch / pill).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.haptic = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Palm "selection click" haptic before [onTap] runs (standard settings UX).
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onTap = this.onTap;

    void handleTap() {
      if (haptic && onTap != null) HapticFeedback.selectionClick();
      onTap?.call();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.control,
                height: AppSpacing.control,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.lg,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: AppFontSize.lg,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
