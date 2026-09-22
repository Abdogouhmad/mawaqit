// The schema DSL is a dev-time build input (home_widget_cli), not app code.
// ignore_for_file: depend_on_referenced_packages
import 'package:home_widget_generator/home_widget_generator.dart';

@HomeWidget(
  name: 'PrayerWidget',
  description: "Today's prayer times",
  android: HomeWidgetAndroidConfiguration(
    minWidth: 250,
    minHeight: 110,
    targetCellWidth: 4,
    targetCellHeight: 2,
    resizeMode: HWAndroidResizeMode.horizontal,
    widgetCategory: HWAndroidWidgetCategory.homeScreen,
    updatePeriodMillis: 1800000,
  ),
  widget: HWPadding(
    padding: HWEdgeInsets.all(12),
    child: HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
      children: [
        HWRow(
          mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
          children: [
            HWText(
              HWString('nextPrayerName', defaultValue: '—'),
              style: HWRoleTextStyle(
                role: HWTextStyleRole.title,
                fontWeight: HWFontWeight.bold,
              ),
            ),
            HWText(
              HWString('nextPrayerTime', defaultValue: '--:--'),
              style: HWRoleTextStyle(role: HWTextStyleRole.title),
            ),
          ],
        ),
        HWText(
          HWString('nextPrayerCountdown', defaultValue: ''),
          style: HWRoleTextStyle(
            role: HWTextStyleRole.caption,
            color: HWDefaultColor(HWColorRole.contentSecondary),
          ),
        ),
        HWRow(
          mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
          children: [
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWText(
                  HWString('fajrName'),
                  style: HWRoleTextStyle(role: HWTextStyleRole.caption),
                ),
                HWText(
                  HWString('fajrTime'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
              ],
            ),
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWText(
                  HWString('dhuhrName'),
                  style: HWRoleTextStyle(role: HWTextStyleRole.caption),
                ),
                HWText(
                  HWString('dhuhrTime'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
              ],
            ),
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWText(
                  HWString('asrName'),
                  style: HWRoleTextStyle(role: HWTextStyleRole.caption),
                ),
                HWText(
                  HWString('asrTime'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
              ],
            ),
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWText(
                  HWString('maghribName'),
                  style: HWRoleTextStyle(role: HWTextStyleRole.caption),
                ),
                HWText(
                  HWString('maghribTime'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
              ],
            ),
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWText(
                  HWString('ishaName'),
                  style: HWRoleTextStyle(role: HWTextStyleRole.caption),
                ),
                HWText(
                  HWString('ishaTime'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ),
)
class PrayerWidget {}