// ignore_for_file: depend_on_referenced_packages
import 'package:home_widget_generator/home_widget_generator.dart';
import 'package:mawaqit/core/theme/colors.dart';

@HomeWidget(
  name: 'PrayerWidget',
  description: 'Next prayer, live countdown, and daily sequence',

  android: HomeWidgetAndroidConfiguration(
    minWidth: 170,
    minHeight: 170,
    targetCellWidth: 2,
    targetCellHeight: 2,
    resizeMode: HWAndroidResizeMode.horizontal,
    widgetCategory: HWAndroidWidgetCategory.homeScreen,
    updatePeriodMillis: 1800000,
    applyContentPadding: false,
  ),

  widget: HWSizedBox.expand(
    child: HWDecoratedBox(
      decoration: HWBoxDecoration(
        color: HWColor.themed(
          light: HWColor.fixed(AppColors.widgetCanvasLightArgb),
          dark: HWColor.fixed(AppColors.widgetCanvasDarkArgb),
        ),
        border: HWBoxBorder(
          radius: 24, // Softer, more modern corner radius
          thickness: 1,
          color: HWColor.themed(
            light: HWColor.fixed(AppColors.widgetHairlineLightArgb),
            dark: HWColor.fixed(AppColors.widgetHairlineDarkArgb),
          ),
        ),
      ),
      child: HWPadding(
        padding: HWEdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: HWColumn(
          crossAxisAlignment: HWCrossAxisAlignment.start,
          mainAxisAlignment: HWMainAxisAlignment
              .spaceBetween, // Pushes content to top and bottom
          children: [
            // ─────────────────────────────────────────
            // 1. HEADER: Brand + Location
            // ─────────────────────────────────────────
            HWRow(
              mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWRow(
                  crossAxisAlignment: HWCrossAxisAlignment.center,
                  children: [
                    HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.primaryLightArgb),
                          dark: HWColor.fixed(AppColors.primaryDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 4, thickness: 0),
                      ),
                      child: HWSizedBox(width: 8, height: 8),
                    ),
                    HWSizedBox(width: 6),
                    HWText.fixed(
                      'MAWAQIT',
                      style: HWRoleTextStyle(
                        role: HWTextStyleRole.caption,
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.primaryLightArgb),
                          dark: HWColor.fixed(AppColors.radiantSageArgb),
                        ),
                        fontWeight: HWFontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                HWText(
                  HWString('locationShort', defaultValue: '—'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    color: HWDefaultColor(HWColorRole.contentSecondary),
                    fontWeight: HWFontWeight.medium,
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────
            // 2. HERO: Next Prayer Focus
            // ─────────────────────────────────────────
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.start,
              children: [
                HWText.fixed(
                  'NEXT PRAYER',
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    color: HWDefaultColor(HWColorRole.contentSecondary),
                    fontWeight: HWFontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                HWSizedBox(height: 4),
                HWText(
                  HWString('nextPrayerName', defaultValue: 'ASR'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.headline,
                    color: HWDefaultColor(HWColorRole.contentPrimary),
                    fontWeight: HWFontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                HWSizedBox(height: 8),
                HWText(
                  HWString('nextPrayerCountdown', defaultValue: '01h 24m'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.title,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
                HWSizedBox(height: 4),
                HWText(
                  HWString('nextPrayerTime', defaultValue: '3:45 PM'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.body,
                    color: HWDefaultColor(HWColorRole.contentSecondary),
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────
            // 3. FOOTER: Minimalist 5-Prayer Sequence
            // Clean, evenly spaced dots. No connectors.
            // ─────────────────────────────────────────
            HWRow(
              mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                // Fajr
                HWBoolConditional(
                  data: HWBool('fajrIsActive', defaultValue: false),
                  whenTrue: HWDecoratedBox(
                    decoration: HWBoxDecoration(
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.primaryLightArgb),
                        dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                      ),
                      border: HWBoxBorder(radius: 999, thickness: 0),
                    ),
                    child: HWSizedBox(width: 8, height: 8),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('fajrIsPast', defaultValue: false),
                    whenTrue: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                          dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                    whenFalse: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(
                            AppColors.widgetMutedTintLightArgb,
                          ),
                          dark: HWColor.fixed(
                            AppColors.widgetMutedTintDarkArgb,
                          ),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                  ),
                ),
                // Dhuhr
                HWBoolConditional(
                  data: HWBool('dhuhrIsActive', defaultValue: false),
                  whenTrue: HWDecoratedBox(
                    decoration: HWBoxDecoration(
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.primaryLightArgb),
                        dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                      ),
                      border: HWBoxBorder(radius: 999, thickness: 0),
                    ),
                    child: HWSizedBox(width: 8, height: 8),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('dhuhrIsPast', defaultValue: false),
                    whenTrue: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                          dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                    whenFalse: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(
                            AppColors.widgetMutedTintLightArgb,
                          ),
                          dark: HWColor.fixed(
                            AppColors.widgetMutedTintDarkArgb,
                          ),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                  ),
                ),
                // Asr
                HWBoolConditional(
                  data: HWBool('asrIsActive', defaultValue: false),
                  whenTrue: HWDecoratedBox(
                    decoration: HWBoxDecoration(
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.primaryLightArgb),
                        dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                      ),
                      border: HWBoxBorder(radius: 999, thickness: 0),
                    ),
                    child: HWSizedBox(width: 8, height: 8),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('asrIsPast', defaultValue: false),
                    whenTrue: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                          dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                    whenFalse: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(
                            AppColors.widgetMutedTintLightArgb,
                          ),
                          dark: HWColor.fixed(
                            AppColors.widgetMutedTintDarkArgb,
                          ),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                  ),
                ),
                // Maghrib
                HWBoolConditional(
                  data: HWBool('maghribIsActive', defaultValue: false),
                  whenTrue: HWDecoratedBox(
                    decoration: HWBoxDecoration(
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.primaryLightArgb),
                        dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                      ),
                      border: HWBoxBorder(radius: 999, thickness: 0),
                    ),
                    child: HWSizedBox(width: 8, height: 8),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('maghribIsPast', defaultValue: false),
                    whenTrue: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                          dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                    whenFalse: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(
                            AppColors.widgetMutedTintLightArgb,
                          ),
                          dark: HWColor.fixed(
                            AppColors.widgetMutedTintDarkArgb,
                          ),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                  ),
                ),
                // Isha
                HWBoolConditional(
                  data: HWBool('ishaIsActive', defaultValue: false),
                  whenTrue: HWDecoratedBox(
                    decoration: HWBoxDecoration(
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.primaryLightArgb),
                        dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                      ),
                      border: HWBoxBorder(radius: 999, thickness: 0),
                    ),
                    child: HWSizedBox(width: 8, height: 8),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('ishaIsPast', defaultValue: false),
                    whenTrue: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                          dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                    whenFalse: HWDecoratedBox(
                      decoration: HWBoxDecoration(
                        color: HWColor.themed(
                          light: HWColor.fixed(
                            AppColors.widgetMutedTintLightArgb,
                          ),
                          dark: HWColor.fixed(
                            AppColors.widgetMutedTintDarkArgb,
                          ),
                        ),
                        border: HWBoxBorder(radius: 999, thickness: 0),
                      ),
                      child: HWSizedBox(width: 6, height: 6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
)
class PrayerWidget {}
