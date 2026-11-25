// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart' show Icons;
import 'package:home_widget_generator/home_widget_generator.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/src/home_widget/widget_tokens.dart';

// ─────────────────────────── Palette (token mirrors) ─────────────────────────
const HWColor _accent = HWColor.themed(
  light: HWColor.fixed(AppColors.emeraldPrimaryArgb),
  dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
);
const HWColor _hairline = HWColor.themed(
  light: HWColor.fixed(AppColors.widgetHairlineLightArgb),
  dark: HWColor.fixed(AppColors.widgetHairlineDarkArgb),
);
const HWColor _primary = HWDefaultColor(HWColorRole.contentPrimary);
const HWColor _secondary = HWDefaultColor(HWColorRole.contentSecondary);

const HWColor _standardCanvas = HWColor.themed(
  light: HWColor.fixed(AppColors.widgetCanvasLightArgb),
  dark: HWColor.fixed(AppColors.widgetCanvasDarkArgb),
);
const HWColor _standardMuted = HWColor.themed(
  light: HWColor.fixed(AppColors.widgetMutedLightArgb),
  dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
);
const HWColor _standardMutedTint = HWColor.themed(
  light: HWColor.fixed(AppColors.widgetMutedTintLightArgb),
  dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
);

// True black is a separate branch, not a third theme value: only the canvas
// and the two faint dot tints move, while every accent keeps its palette role.
const HWColor _amoledCanvas = HWColor.fixed(WidgetTokens.canvasAmoledArgb);
const HWColor _amoledMuted = HWColor.fixed(WidgetTokens.mutedAmoledArgb);
const HWColor _amoledMutedTint = HWColor.fixed(
  WidgetTokens.mutedTintAmoledArgb,
);

// ─────────────────────────── Shared content ─────────────────────────────────

/// Static labels are compiled into platform string resources by the generator.
/// That gives the gallery real French/Arabic previews and keeps Arabic text
/// Arabic without adding a runtime data key that could go stale.
/// The brand survives as a single accent mark. Dropping the wordmark buys the
/// small card one more text line at 200% system text without inventing a new
/// size token.
const HWWidget _brandMark = HWIcon.fixed(
  Icons.mosque_rounded,
  size: WidgetTokens.iconSm,
  color: _accent,
);

const HWWidget _location = HWText(
  HWString('locationShort', defaultValue: '—'),
  style: HWRoleTextStyle(
    role: HWTextStyleRole.captionSmall,
    color: _secondary,
    fontWeight: HWFontWeight.w500,
  ),
);

/// 2×2: the two facts a glance needs, in the two roles the palette reserves for
/// identity and signal. Nothing else competes at large text sizes.
const HWWidget _heroSmall = HWColumn(
  crossAxisAlignment: HWCrossAxisAlignment.start,
  spacing: WidgetTokens.spaceXxs,
  children: [
    HWText(
      HWString('nextPrayerName', defaultValue: '—'),
      style: HWRoleTextStyle(
        role: HWTextStyleRole.headline,
        color: _primary,
        fontWeight: HWFontWeight.bold,
      ),
    ),
    HWText(
      HWString('nextPrayerCountdown', defaultValue: '—'),
      style: HWRoleTextStyle(
        role: HWTextStyleRole.title,
        color: _accent,
        fontWeight: HWFontWeight.bold,
      ),
    ),
  ],
);

/// 4×2: the countdown stays the signal, while the absolute time gives the card
/// a second, non-stale fact when the last snapshot is a few minutes old.
const HWWidget _heroMedium = HWRow(
  mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
  crossAxisAlignment: HWCrossAxisAlignment.center,
  children: [
    HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      spacing: WidgetTokens.spaceXxs,
      children: [
        HWText(
          HWString('nextPrayerName', defaultValue: '—'),
          style: HWRoleTextStyle(
            role: HWTextStyleRole.headline,
            color: _primary,
            fontWeight: HWFontWeight.bold,
          ),
        ),
        HWText(
          HWString('nextPrayerTime', defaultValue: '—'),
          style: HWRoleTextStyle(
            role: HWTextStyleRole.captionSmall,
            color: _secondary,
            fontWeight: HWFontWeight.w500,
          ),
        ),
      ],
    ),
    HWText(
      HWString('nextPrayerCountdown', defaultValue: '—'),
      textAlign: HWTextAlign.end,
      style: HWRoleTextStyle(
        role: HWTextStyleRole.title,
        color: _accent,
        fontWeight: HWFontWeight.bold,
      ),
    ),
  ],
);

const HWWidget _hijri = HWBoolConditional(
  data: HWBool('showHijri', defaultValue: true),
  whenTrue: HWText(
    HWString('hijriDate', defaultValue: ''),
    textAlign: HWTextAlign.end,
    style: HWRoleTextStyle(
      role: HWTextStyleRole.captionSmall,
      color: _secondary,
    ),
  ),
  whenFalse: HWSizedBox.shrink(),
);

/// Short enough to share the sequence row at 200% text; the full explanation
/// lives in Settings → Home-screen widget, where there is room to read it.
const HWWidget _tapHint = HWBoolConditional(
  data: HWBool('showQuickActions', defaultValue: true),
  whenTrue: HWText.localized(
    {'en': 'Times', 'fr': 'Horaires', 'ar': 'المواقيت'},
    textAlign: HWTextAlign.end,
    style: HWRoleTextStyle(
      role: HWTextStyleRole.captionSmall,
      color: _secondary,
      fontWeight: HWFontWeight.w500,
    ),
  ),
  whenFalse: HWSizedBox.shrink(),
);

// ─────────────────────────── Five-dot sequence ──────────────────────────────
// Two const rows, one per canvas palette. Dart annotations cannot call const
// functions, so the only way to vary a tint is to declare the variants.

const HWWidget _activeDot = HWIcon.fixed(
  Icons.circle,
  size: WidgetTokens.dotActive,
  color: _accent,
);
const HWWidget _standardPastDot = HWIcon.fixed(
  Icons.circle,
  size: WidgetTokens.dotIdle,
  color: _standardMuted,
);
const HWWidget _standardFutureDot = HWIcon.fixed(
  Icons.circle,
  size: WidgetTokens.dotIdle,
  color: _standardMutedTint,
);
const HWWidget _amoledPastDot = HWIcon.fixed(
  Icons.circle,
  size: WidgetTokens.dotIdle,
  color: _amoledMuted,
);
const HWWidget _amoledFutureDot = HWIcon.fixed(
  Icons.circle,
  size: WidgetTokens.dotIdle,
  color: _amoledMutedTint,
);

const HWWidget _fajrStandardDot = HWBoolConditional(
  data: HWBool('fajrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('fajrIsPast', defaultValue: false),
    whenTrue: _standardPastDot,
    whenFalse: _standardFutureDot,
  ),
);
const HWWidget _dhuhrStandardDot = HWBoolConditional(
  data: HWBool('dhuhrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('dhuhrIsPast', defaultValue: false),
    whenTrue: _standardPastDot,
    whenFalse: _standardFutureDot,
  ),
);
const HWWidget _asrStandardDot = HWBoolConditional(
  data: HWBool('asrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('asrIsPast', defaultValue: false),
    whenTrue: _standardPastDot,
    whenFalse: _standardFutureDot,
  ),
);
const HWWidget _maghribStandardDot = HWBoolConditional(
  data: HWBool('maghribIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('maghribIsPast', defaultValue: false),
    whenTrue: _standardPastDot,
    whenFalse: _standardFutureDot,
  ),
);
const HWWidget _ishaStandardDot = HWBoolConditional(
  data: HWBool('ishaIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('ishaIsPast', defaultValue: false),
    whenTrue: _standardPastDot,
    whenFalse: _standardFutureDot,
  ),
);

const HWWidget _fajrAmoledDot = HWBoolConditional(
  data: HWBool('fajrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('fajrIsPast', defaultValue: false),
    whenTrue: _amoledPastDot,
    whenFalse: _amoledFutureDot,
  ),
);
const HWWidget _dhuhrAmoledDot = HWBoolConditional(
  data: HWBool('dhuhrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('dhuhrIsPast', defaultValue: false),
    whenTrue: _amoledPastDot,
    whenFalse: _amoledFutureDot,
  ),
);
const HWWidget _asrAmoledDot = HWBoolConditional(
  data: HWBool('asrIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('asrIsPast', defaultValue: false),
    whenTrue: _amoledPastDot,
    whenFalse: _amoledFutureDot,
  ),
);
const HWWidget _maghribAmoledDot = HWBoolConditional(
  data: HWBool('maghribIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('maghribIsPast', defaultValue: false),
    whenTrue: _amoledPastDot,
    whenFalse: _amoledFutureDot,
  ),
);
const HWWidget _ishaAmoledDot = HWBoolConditional(
  data: HWBool('ishaIsActive', defaultValue: false),
  whenTrue: _activeDot,
  whenFalse: HWBoolConditional(
    data: HWBool('ishaIsPast', defaultValue: false),
    whenTrue: _amoledPastDot,
    whenFalse: _amoledFutureDot,
  ),
);

const HWWidget _standardDots = HWRow(
  mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
  crossAxisAlignment: HWCrossAxisAlignment.center,
  children: [
    _fajrStandardDot,
    _dhuhrStandardDot,
    _asrStandardDot,
    _maghribStandardDot,
    _ishaStandardDot,
  ],
);
const HWWidget _amoledDots = HWRow(
  mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
  crossAxisAlignment: HWCrossAxisAlignment.center,
  children: [
    _fajrAmoledDot,
    _dhuhrAmoledDot,
    _asrAmoledDot,
    _maghribAmoledDot,
    _ishaAmoledDot,
  ],
);

// ─────────────────────────────── Card shells ────────────────────────────────

/// One top line instead of a stacked brand block. The icon carries the mark;
/// the location and optional Hijri date share the line in their logical order.
const HWWidget _topLine = HWSizedBox(
  width: double.infinity,
  child: HWRow(
    mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
    crossAxisAlignment: HWCrossAxisAlignment.center,
    children: [
      HWRow(
        crossAxisAlignment: HWCrossAxisAlignment.center,
        children: [
          _brandMark,
          HWPadding(
            padding: HWEdgeInsets.only(left: WidgetTokens.spaceXxs),
            child: _location,
          ),
        ],
      ),
      _hijri,
    ],
  ),
);

/// The five-dot sequence and the route hint share one row. Wrapping the row in
/// an infinite-width box is what lets `spaceBetween` spread the dots in Glance.
const HWWidget _standardFooter = HWSizedBox(
  width: double.infinity,
  child: HWRow(
    mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
    crossAxisAlignment: HWCrossAxisAlignment.center,
    children: [_standardDots, _tapHint],
  ),
);
const HWWidget _amoledFooter = HWSizedBox(
  width: double.infinity,
  child: HWRow(
    mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
    crossAxisAlignment: HWCrossAxisAlignment.center,
    children: [_amoledDots, _tapHint],
  ),
);

// Padding is the smallest spacing step so the text has the whole cell at 200%
// system text. The hairline border and radius still give the card its edge.
const HWWidget _smallStandardCard = HWSizedBox.expand(
  child: HWDecoratedBox(
    decoration: HWBoxDecoration(
      color: _standardCanvas,
      borderRadius: HWBorderRadius.circular(WidgetTokens.radiusLg),
      border: HWBoxBorder(
        thickness: WidgetTokens.strokeHairline,
        color: _hairline,
      ),
    ),
    child: HWPadding(
      padding: HWEdgeInsets.all(WidgetTokens.spaceXs),
      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
        children: [_heroSmall, _standardDots],
      ),
    ),
  ),
);

const HWWidget _smallAmoledCard = HWSizedBox.expand(
  child: HWDecoratedBox(
    decoration: HWBoxDecoration(
      color: _amoledCanvas,
      borderRadius: HWBorderRadius.circular(WidgetTokens.radiusLg),
      border: HWBoxBorder(
        thickness: WidgetTokens.strokeHairline,
        color: _hairline,
      ),
    ),
    child: HWPadding(
      padding: HWEdgeInsets.all(WidgetTokens.spaceXs),
      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
        children: [_heroSmall, _amoledDots],
      ),
    ),
  ),
);

const HWWidget _mediumStandardCard = HWSizedBox.expand(
  child: HWDecoratedBox(
    decoration: HWBoxDecoration(
      color: _standardCanvas,
      borderRadius: HWBorderRadius.circular(WidgetTokens.radiusLg),
      border: HWBoxBorder(
        thickness: WidgetTokens.strokeHairline,
        color: _hairline,
      ),
    ),
    child: HWPadding(
      padding: HWEdgeInsets.all(WidgetTokens.spaceXs),
      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
        children: [_topLine, _heroMedium, _standardFooter],
      ),
    ),
  ),
);

const HWWidget _mediumAmoledCard = HWSizedBox.expand(
  child: HWDecoratedBox(
    decoration: HWBoxDecoration(
      color: _amoledCanvas,
      borderRadius: HWBorderRadius.circular(WidgetTokens.radiusLg),
      border: HWBoxBorder(
        thickness: WidgetTokens.strokeHairline,
        color: _hairline,
      ),
    ),
    child: HWPadding(
      padding: HWEdgeInsets.all(WidgetTokens.spaceXs),
      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
        children: [_topLine, _heroMedium, _amoledFooter],
      ),
    ),
  ),
);

@HomeWidget(
  name: 'PrayerWidget',
  description: 'Next prayer, live countdown, and daily sequence',

  // Tapping the card lands on the prayer-times tab, which is what the card is
  // showing. Not cosmetic: `widgetUrl` is what makes the generator emit
  // `actionStartActivity<MainActivity>(Uri.parse(...))` instead of the bare
  // one-argument overload. Only the URI overload goes through the plugin's
  // `HomeWidgetLaunchIntent`, which attaches the `ActivityOptions` carrying
  // `MODE_BACKGROUND_ACTIVITY_START_ALLOWED` — without it Android 14+ treats
  // the launcher's tap as a background activity start and refuses it, which is
  // the white screen this replaces.
  //
  // The generator demands an absolute URI, so the tab path rides in the path
  // with an empty authority: `mawaqit:///times` → `uri.path == '/times'`.
  // Flutter's own deep linking is off (no `flutter_deeplinking_enabled` in the
  // manifest), so nothing else tries to interpret this scheme; only
  // `HomeWidget.initiallyLaunchedFromHomeWidget` / `widgetClicked` read it.
  widgetUrl: WidgetTokens.launchUrl,

  // Gallery entries and any `HWText.localized` strings ship as real
  // values-* string resources, so the launcher preview follows the system
  // language in all three supported locales.
  localization: HomeWidgetLocalization(
    defaultLocale: 'en',
    supportedLocales: ['en', 'fr', 'ar'],
    name: {
      'en': 'Mawaqit prayers',
      'fr': 'Prières Mawaqit',
      'ar': 'مواقيت الصلاة',
    },
    description: {
      'en': 'Next prayer, countdown, and daily sequence',
      'fr': 'Prochaine prière, compte à rebours et séquence du jour',
      'ar': 'الصلاة القادمة والعد التنازلي وترتيب الصلوات',
    },
  ),

  android: HomeWidgetAndroidConfiguration(
    minWidth: 110,
    minHeight: 110,
    minResizeWidth: 110,
    minResizeHeight: 110,
    maxResizeWidth: 410,
    maxResizeHeight: 170,
    targetCellWidth: 2,
    targetCellHeight: 2,
    resizeMode: HWAndroidResizeMode.horizontal,
    widgetCategory: HWAndroidWidgetCategory.homeScreen,
    updatePeriodMillis: 1800000,
    applyContentPadding: false,
  ),

  widget: HWSizeAdaptive(
    small: HWBoolConditional(
      data: HWBool('amoled', defaultValue: false),
      whenTrue: _smallAmoledCard,
      whenFalse: _smallStandardCard,
    ),
    medium: HWBoolConditional(
      data: HWBool('amoled', defaultValue: false),
      whenTrue: _mediumAmoledCard,
      whenFalse: _mediumStandardCard,
    ),
    androidSizes: {
      HWWidgetFamily.systemSmall: HWSize.cells(2, 2),
      HWWidgetFamily.systemMedium: HWSize.cells(4, 2),
    },
  ),
)
class PrayerWidget {}
