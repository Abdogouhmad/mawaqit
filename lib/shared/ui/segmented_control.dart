import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/app_tokens.dart';

/// Pill-shaped segmented control (design "None/5/10/15", "System/Light/Dark").
///
/// The selected highlight is a single pill that slides between segments, with
/// the label/icon colours cross-fading, so switching feels continuous rather
/// than a hard repaint.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icons = const [],
  });

  /// (value, label) pairs.
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final List<IconData> icons;

  /// Below this segment width the per-segment icon is dropped.
  ///
  /// An icon costs [AppIconSize.md] plus [AppSpacing.sm] — 23dp — which is a
  /// third of what a four-way control has to give each label on a 393dp phone.
  /// The label is what carries the meaning ("English" is unambiguous where a
  /// globe icon is not), so the icon is the first thing to go. Two- and
  /// three-way controls are wide enough to keep theirs.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedIndex = options.indexWhere((option) => option.$1 == value);
    final duration = AppSpring.durationOf(context, fallback: AppMotion.control);
    const padding = AppSpacing.xs;

    return Container(
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              (constraints.maxWidth - padding * 2) / options.length;
          final showIcons =
              icons.isNotEmpty && segmentWidth >= AppSize.minSegmentForIcon;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: AppMotion.standard,
                left: selectedIndex < 0
                    ? -segmentWidth
                    : selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: selectedIndex < 0
                      ? AppOpacity.none
                      : AppOpacity.full,
                  child: const _HighlightPill(),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: _segment(
                        context,
                        i,
                        showIcon: showIcons,
                        duration: duration,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    int index, {
    required bool showIcon,
    required Duration duration,
  }) {
    final optionValue = options[index].$1;
    final label = options[index].$2;
    final scheme = Theme.of(context).colorScheme;
    final selected = optionValue == value;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!selected) onChanged(optionValue);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon && icons.length > index) ...[
              TweenAnimationBuilder<Color?>(
                duration: duration,
                curve: AppMotion.standard,
                tween: ColorTween(end: foreground),
                builder: (context, color, _) => Icon(
                  icons[index],
                  size: AppIconSize.md,
                  color: color ?? foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            // `Flexible` is load-bearing, not defensive. A `Text` placed
            // directly in a `Row` is handed an unbounded main-axis width, so each
            // label laid out at its full intrinsic width and painted past the
            // segment — which is what overflowed the language control once it
            // grew to four options. Truncating keeps the segment's own bounds
            // authoritative at any width, text scale, or translation length.
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: AppMotion.standard,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.mini),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: AppElevation.controlBlur,
            offset: AppElevation.controlOffset,
          ),
        ],
      ),
    );
  }
}
