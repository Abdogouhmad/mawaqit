import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';

/// The app's single bottom-navigation chrome.
///
/// A standard Material 3 `NavigationBar` in `Scaffold.bottomNavigationBar`, with
/// every colour and dimension resolved from tokens. Keeping this in one widget
/// means the shell, the component gallery and the layout tests all exercise the
/// same bar rather than three near-identical copies.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // labelMedium, not labelSmall: Material defaults to 14dp here and dropping
    // to 11dp made the bar look faint beside the rest of the type scale.
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final duration = AppSpring.durationOf(context, fallback: AppMotion.route);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: AppSize.navigationIcon,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          backgroundColor: scheme.surfaceContainer,
          surfaceTintColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          indicatorColor: scheme.primaryContainer,
          indicatorShape: AppShape.pill,
          elevation: AppElevation.none,
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: AppOpacity.navOverlay),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelPadding: const EdgeInsets.only(
            top: AppSize.navigationLabelPadding,
          ),
          height: AppSize.navigationBarHeight,
          animationDuration: duration,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            final selected = states.contains(WidgetState.selected);
            return labelStyle?.copyWith(
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: selected ? AppWeight.bold : AppWeight.medium,
            );
          }),
        ),
      ),
    );
  }
}
