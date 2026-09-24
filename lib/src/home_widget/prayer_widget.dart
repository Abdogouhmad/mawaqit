// The schema DSL is a dev-time build input
// (home_widget_cli), not app code.

// ignore_for_file: depend_on_referenced_packages
import 'package:home_widget_generator/home_widget_generator.dart';

// NOTE: the whole `widget:` tree must stay a single constant expression —
// the generator resolves it with the analyzer's const evaluator — so bespoke
// sub-widgets (dots, connectors) are inlined below instead of factored into
// helper functions.

@HomeWidget(
  name: 'PrayerWidget',
  description: "Today's prayer times",

  android: HomeWidgetAndroidConfiguration(
    minWidth: 160,
    minHeight: 160,
    targetCellWidth: 2,
    targetCellHeight: 2,
    resizeMode: HWAndroidResizeMode.horizontal,
    widgetCategory: HWAndroidWidgetCategory.homeScreen,
    updatePeriodMillis: 1800000,
  ),

  // Modern, minimal 2×2 card (no progress bar): a quiet brand + location
  // header, the next prayer as the hero (big name, large time beneath it)
  // and the countdown as a solid sage pill. Four data fields, three rows —
  // everything readable at a glance, nothing competing with the countdown.
  widget: HWFill(
    child: HWPadding(
      padding: HWEdgeInsets.all(14),

      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,

        children: [
          // ─────────────────────────────────────────
          // HEADER: brand + location
          // ─────────────────────────────────────────

          HWRow(
            mainAxisAlignment: HWMainAxisAlignment.spaceBetween,

            children: [
              HWText.fixed(
                'MAWAQIT',
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWColor.fixed(0xFF2E7D5B),
                  fontWeight: HWFontWeight.bold,
                ),
              ),

              HWText(
                HWString('locationShort', defaultValue: '—'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWDefaultColor(HWColorRole.contentSecondary),
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────
          // HERO: next prayer name + large time
          // ─────────────────────────────────────────
          HWColumn(
            crossAxisAlignment: HWCrossAxisAlignment.start,

            children: [
              HWText(
                HWString('nextPrayerName', defaultValue: '—'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.title,
                  fontWeight: HWFontWeight.bold,
                  color: HWDefaultColor(HWColorRole.contentPrimary),
                ),
              ),

              HWText(
                HWString('nextPrayerTime', defaultValue: '--:--'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.headline,
                  color: HWDefaultColor(HWColorRole.contentPrimary),
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────
          // COUNTDOWN: solid sage pill
          // ─────────────────────────────────────────
          HWColoredBox(
            color: HWColor.fixed(0xFF2E7D5B),

            child: HWPadding(
              padding: HWEdgeInsets.symmetric(vertical: 6, horizontal: 12),

              child: HWText(
                HWString('nextPrayerCountdown', defaultValue: 'NEXT IN —'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWColor.fixed(0xFFFFFFFF),
                  fontWeight: HWFontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
class PrayerWidget {}
