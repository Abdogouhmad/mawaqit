import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/tokens.dart';

/// Generic radio-style picker bottom sheet used by the settings screen to
/// choose a calculation method, madhab, or any single-select list.
///
/// The current value is checked; tapping an option pops the sheet with it.
Future<T?> showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) label,
  required T current,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.giga,
              AppSpacing.xs,
              AppSpacing.giga,
              AppSpacing.xl,
            ),
            child: Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == current;
                return ListTile(
                  title: Text(label(option)),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          size: AppIconSize.xl,
                          color: scheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: scheme.primary.withValues(alpha: 0.06),
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ),
  );
}