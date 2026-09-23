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

  // Compact 2×2 card: header, big next prayer, countdown and a day-progress
  // bar. The following-prayer and five-dot timeline rows were dropped so the
  // layout keeps generous breathing room at the 2×2 footprint (the full
  // timeline already lives in the home screen).
  widget: HWFill(
    child: HWPadding(
      padding: HWEdgeInsets.all(14),

      child: HWColumn(
        crossAxisAlignment: HWCrossAxisAlignment.start,
        mainAxisAlignment: HWMainAxisAlignment.spaceBetween,

        children: [
          // ─────────────────────────────────────────
          // HEADER: brand mark + location
          // ─────────────────────────────────────────

          HWRow(
            mainAxisAlignment: HWMainAxisAlignment.spaceBetween,

            children: [
              HWRow(
                children: [
                  HWText.fixed(
                    '◷',
                    style: HWRoleTextStyle(
                      role: HWTextStyleRole.caption,
                      color: HWColor.fixed(0xFF2E7D5B),
                      fontWeight: HWFontWeight.bold,
                    ),
                  ),

                  HWText.fixed(
                    ' Waqt',
                    style: HWRoleTextStyle(
                      role: HWTextStyleRole.caption,
                      fontWeight: HWFontWeight.bold,
                      color: HWDefaultColor(HWColorRole.contentPrimary),
                    ),
                  ),
                ],
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
          // NEXT PRAYER NAME + TIME
          // ─────────────────────────────────────────
          HWRow(
            mainAxisAlignment: HWMainAxisAlignment.spaceBetween,

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
                  role: HWTextStyleRole.caption,
                  fontWeight: HWFontWeight.bold,
                  color: HWDefaultColor(HWColorRole.contentPrimary),
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────
          // COUNTDOWN UNTIL THE NEXT PRAYER
          // ─────────────────────────────────────────
          HWRow(
            children: [
              HWText.fixed(
                '●',
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWColor.fixed(0xFF2E7D5B),
                ),
              ),

              HWText(
                HWString('nextPrayerCountdown', defaultValue: 'NEXT IN —'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWColor.fixed(0xFF2E7D5B),
                  fontWeight: HWFontWeight.bold,
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────
          // DAY-PROGRESS BAR
          //
          // We send the filled/remaining portions from Dart because the
          // generator DSL doesn't need to know the actual prayer times.
          // Filled reads as a solid track, remaining as a dotted rail so the
          // progress is legible at a glance.
          // ─────────────────────────────────────────
          HWRow(
            children: [
              HWText(
                HWString('progressFilled', defaultValue: '━━━━━━'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  fontWeight: HWFontWeight.bold,
                  color: HWColor.fixed(0xFF2E7D5B),
                ),
              ),

              HWText(
                HWString('progressRemaining', defaultValue: '······'),
                style: HWRoleTextStyle(
                  role: HWTextStyleRole.caption,
                  color: HWDefaultColor(HWColorRole.contentSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
)
class PrayerWidget {}
