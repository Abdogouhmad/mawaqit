import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Shared "work in progress" state for lists and cards.
///
/// Deliberately quieter than a full-screen route dialog: it occupies the same
/// space the content will, so a refresh does not make the screen jump.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label,
    this.indicatorSize = AppSpacing.tera,
    this.padding = const EdgeInsets.all(AppSpacing.tera),
  });

  final String? label;
  final double indicatorSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: AppStroke.spinner,
                color: scheme.primary,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.xl),
              UiText(
                label!,
                type: UiTextType.labelMedium,
                color: scheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
