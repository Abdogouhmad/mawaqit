import 'package:flutter/material.dart';

import 'package:mawaqit/core/ui/theme/shapes.dart';

/// How the five prayer times are arranged inside one day of the month, and at
/// what size.
///
/// The month grid used to be a fixed five-column table with one `FittedBox` per
/// cell, and measurement makes that design's defect plain: on a 360dp phone in
/// English, "12:45 PM" sets at 96dp in [UiTextType.labelMedium], so five of them
/// need 480dp inside a 320dp content column. Every time was therefore scaled to
/// roughly 0.4 of its nominal size — about 5dp tall — and the screen looked fine
/// only because nobody compared it against the type it claimed to use. At 200%
/// text scale, which feat.md §6 requires be safe, the same arithmetic took the
/// times to 0.22.
///
/// This sizes the grid *up* from what fits instead: it measures the strings the
/// month will really draw, then picks the combination of column count and type
/// size that renders them at full size. A 24-hour clock and an Arabic calendar
/// both earn more columns because their glyphs are narrower; a 12-hour clock in
/// English gets fewer columns and stays legible.
@immutable
class PrayerGrid {
  const PrayerGrid({required this.columns, required this.timeStyle});

  /// Prayer columns per row. Between [minColumns] and the prayer count.
  final int columns;

  /// Style for the time values: the largest on the ladder that fits.
  final TextStyle? timeStyle;

  /// Two columns is the floor.
  ///
  /// Below that the five prayers become a tall single file and a month stops
  /// reading as a month. When even two columns cannot hold a time — a 12-hour
  /// clock at 200% text on a narrow phone — the cell scales down instead, which
  /// still leaves a very large time compared with the 5dp the old grid produced.
  static const int minColumns = 2;

  /// Gap between prayer columns.
  static const double columnGap = AppSpacing.lg;

  /// Fits the largest legible grid into [availableWidth].
  ///
  /// [widestText] is the longest clock string the month will actually draw,
  /// rather than a guess: the width depends on the clock convention (a 12-hour
  /// " PM" is a third wider than a 24-hour one) and on the locale's digits, which
  /// are narrower in Arabic than in Latin. Measuring the real string gets both
  /// right without a special case for either, and it is what lets a 24-hour clock
  /// earn a fifth column that a 12-hour one cannot have.
  ///
  /// Preference order is most columns first, then largest type. A month is easier
  /// to scan when it is short, but it is not worth buying a fifth column by
  /// rendering its contents too small to read.
  static PrayerGrid resolve({
    required TextTheme textTheme,
    required double availableWidth,
    required String widestText,
    required TextScaler textScaler,
    TextDirection direction = TextDirection.ltr,
    int prayerCount = 5,
  }) {
    // Tracking is the one thing stripped here. Tabular figures are fixed-width,
    // so the letter spacing `AppTextTheme` puts on `labelMedium` inserts visible
    // gaps between digits that are meant to form a grid — and it costs about 4%
    // of a clock string's width, which is the difference between three columns
    // and four on a narrow phone.
    final ladder = [
      for (final style in [
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ])
        style?.copyWith(
              letterSpacing: 0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ) ??
            const TextStyle(),
    ];

    for (var columns = prayerCount; columns >= minColumns; columns--) {
      final columnWidth =
          (availableWidth - columnGap * (columns - 1)) / columns;
      for (final style in ladder) {
        if (measure(widestText, style, textScaler, direction: direction) <=
            columnWidth) {
          return PrayerGrid(columns: columns, timeStyle: style);
        }
      }
    }

    return PrayerGrid(columns: minColumns, timeStyle: ladder.last);
  }

  /// Width of [text] in [style] at [scaler].
  ///
  /// `TextPainter` does not read the ambient scaler, so it is threaded in
  /// explicitly: measuring against the raw font size would size the grid for 1x
  /// and overflow at 200%.
  static double measure(
    String text,
    TextStyle style,
    TextScaler scaler, {
    TextDirection direction = TextDirection.ltr,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    return painter.width;
  }

  /// Number of rows the five prayers occupy at this column count.
  ///
  /// Not always whole: three columns leaves two prayers on a short last strip.
  /// That raggedness is shared by [DayRow] and the pinned header, which is the
  /// point — the two are cut from the same [columns].
  int stripsFor(int prayerCount) => (prayerCount / columns).ceil();

  @override
  bool operator ==(Object other) =>
      other is PrayerGrid &&
      other.columns == columns &&
      other.timeStyle == timeStyle;

  @override
  int get hashCode => Object.hash(columns, timeStyle);

  @override
  String toString() => 'PrayerGrid($columns columns)';
}
