import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// "Nothing here yet" — used by every list that can legitimately be empty
/// (no search results, no upcoming events, no months cached).
///
/// Deliberately *not* an error state: it renders without a red tint and without
/// a shake, because the commonest cause is a filter the user just set, not a
/// failure. The optional [action] is how the screen offers the way out, so an
/// empty list never becomes a dead end.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        // Generous side padding so a long [body] wraps into a comfortable
        // measure on a narrow phone instead of a two-word-per-line column.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A tinted disc rather than a bare glyph: on an empty screen there is
            // no other ink on the canvas, and an unbacked icon reads as a
            // rendering mistake.
            Container(
              width: AppSpacing.control * 1.5,
              height: AppSpacing.control * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHigh,
              ),
              child: Icon(
                icon,
                size: AppIconSize.display,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.block),
            UiText(
              title,
              type: UiTextType.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.md),
              UiText(
                body!,
                type: UiTextType.bodyMedium,
                textAlign: TextAlign.center,
                color: scheme.onSurfaceVariant,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.giga),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
