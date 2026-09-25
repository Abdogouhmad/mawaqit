import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';
import 'package:mawaqit/shared/ui/app_card.dart';

/// Groups [SettingsRow]s (or full-width blocks) into one card, separating them
/// with hairline dividers inset to the text column — so every row reads as an
/// aligned list rather than stacked rectangles.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  /// Where the row text starts: card padding + leading icon circle + gap.
  static const double _inset =
      AppSpacing.xxxl + AppSpacing.control + AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant.withValues(alpha: 0.4);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: _inset,
                endIndent: AppSpacing.xxxl,
                color: dividerColor,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
