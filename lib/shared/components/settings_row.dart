import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/shared/ui/app_list_row.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';

/// Settings list row: leading icon in a soft circle, title + subtitle,
/// and a trailing widget (chevron / switch / pill).
///
/// The layout itself lives in [AppListRow]; this wrapper only supplies the
/// settings-specific leading badge and accent subtitle colour. Keeping one
/// implementation of the row prevents another copy of the 200%-text fixes.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.haptic = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Overrides the default accent [subtitle] colour — used to flag a row that
  /// needs attention (e.g. a permission that is not granted yet).
  final Color? subtitleColor;

  final Widget? trailing;
  final VoidCallback? onTap;

  /// Palm "selection click" haptic before [onTap] runs (standard settings UX).
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppListRow(
      title: title,
      subtitle: subtitle,
      subtitleColor: subtitleColor ?? scheme.primary,
      leading: IconBadge(
        icon: icon,
        color: scheme.secondaryContainer.withValues(alpha: AppOpacity.badge),
        foregroundColor: scheme.onSecondaryContainer,
      ),
      trailing: trailing,
      onTap: onTap,
      haptic: haptic,
    );
  }
}
