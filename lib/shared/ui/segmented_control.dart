import 'package:flutter/material.dart';

import 'package:mawaqit/core/theme/colors.dart';
import 'package:mawaqit/core/theme/tokens.dart';

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

  static const Duration _duration = Duration(milliseconds: 280);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedIndex = options.indexWhere((option) => option.$1 == value);
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

          return Stack(
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: selectedIndex < 0
                    ? -segmentWidth
                    : selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: AnimatedOpacity(
                  duration: _duration,
                  opacity: selectedIndex < 0 ? 0 : 1,
                  child: const _HighlightPill(),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(child: _segment(context, i)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
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
            if (icons.length > index) ...[
              TweenAnimationBuilder<Color?>(
                duration: _duration,
                curve: _curve,
                tween: ColorTween(end: foreground),
                builder: (context, color, _) => Icon(
                  icons[index],
                  size: AppIconSize.md,
                  color: color ?? foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            AnimatedDefaultTextStyle(
              duration: _duration,
              curve: _curve,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
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
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
