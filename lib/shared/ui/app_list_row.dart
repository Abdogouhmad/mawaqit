import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// The app's generic list row: an optional leading badge, a title/subtitle
/// column, and an optional trailing control.
///
/// Both the text column and the trailing control are flexible. A trailing
/// `Switch`, pill or chevron must never push the title past the card at 200%
/// text or with a long Arabic translation — the same rule that produced the
/// original tab-layout overflow regression.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.haptic = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Palm "selection click" before [onTap] runs, as in platform settings.
  final bool haptic;

  /// Tighter vertical padding for compact groups such as the Update Center.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onTap = this.onTap;

    void handleTap() {
      if (haptic && onTap != null) HapticFeedback.selectionClick();
      onTap?.call();
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: dense ? AppSpacing.md : AppSpacing.xl,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.xxl),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      title,
                      type: UiTextType.titleMedium,
                      fontSize: AppFontSize.lg,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      UiText(
                        subtitle!,
                        type: UiTextType.labelMedium,
                        color: subtitleColor ?? scheme.onSurfaceVariant,
                        fontWeight: AppWeight.medium,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
