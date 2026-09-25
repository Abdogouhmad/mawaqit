// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart' show Icons;
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
          radius: 24,
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
          mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
          children: [
            // ─────────────────────────────────────────
            // 1. HEADER: icon + brand + location
            // ─────────────────────────────────────────
            HWRow(
              mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                HWRow(
                  crossAxisAlignment: HWCrossAxisAlignment.center,
                  children: [
                    HWPadding(
                      padding: HWEdgeInsets.only(right: 6),
                      child: HWIcon.fixed(
                        Icons.mosque_rounded,
                        size: 16,
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.primaryLightArgb),
                          dark: HWColor.fixed(AppColors.radiantSageArgb),
                        ),
                      ),
                    ),
                    HWText.fixed(
                      'MAWAQIT',
                      style: HWRoleTextStyle(
                        role: HWTextStyleRole.caption,
                        color: HWColor.themed(
                          light: HWColor.fixed(AppColors.primaryLightArgb),
                          dark: HWColor.fixed(AppColors.radiantSageArgb),
                        ),
                        fontWeight: HWFontWeight.bold,
                      ),
                    ),
                  ],
                ),
                HWText(
                  HWString('locationShort', defaultValue: '—'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.caption,
                    color: HWDefaultColor(HWColorRole.contentSecondary),
                    fontWeight: HWFontWeight.w500,
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────
            // 2. HERO: next prayer name, countdown, time — text only
            // ─────────────────────────────────────────
            HWColumn(
              crossAxisAlignment: HWCrossAxisAlignment.start,
              children: [
                HWPadding(
                  padding: HWEdgeInsets.only(bottom: 4),
                  child: HWText.fixed(
                    'NEXT PRAYER',
                    style: HWRoleTextStyle(
                      role: HWTextStyleRole.caption,
                      color: HWDefaultColor(HWColorRole.contentSecondary),
                      fontWeight: HWFontWeight.bold,
                    ),
                  ),
                ),
                HWText(
                  HWString('nextPrayerName', defaultValue: 'ASR'),
                  style: HWRoleTextStyle(
                    role: HWTextStyleRole.headline,
                    color: HWDefaultColor(HWColorRole.contentPrimary),
                    fontWeight: HWFontWeight.bold,
                  ),
                ),
                HWPadding(
                  padding: HWEdgeInsets.only(top: 8, bottom: 4),
                  child: HWText(
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
                ),
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
            // 3. FOOTER: 5-prayer sequence — icon dots, no progress bar
            // ─────────────────────────────────────────
            HWRow(
              mainAxisAlignment: HWMainAxisAlignment.spaceBetween,
              crossAxisAlignment: HWCrossAxisAlignment.center,
              children: [
                // Fajr
                HWBoolConditional(
                  data: HWBool('fajrIsActive', defaultValue: false),
                  whenTrue: HWIcon.fixed(
                    Icons.circle,
                    size: 9,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('fajrIsPast', defaultValue: false),
                    whenTrue: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                        dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                      ),
                    ),
                    whenFalse: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(
                          AppColors.widgetMutedTintLightArgb,
                        ),
                        dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
                      ),
                    ),
                  ),
                ),
                // Dhuhr
                HWBoolConditional(
                  data: HWBool('dhuhrIsActive', defaultValue: false),
                  whenTrue: HWIcon.fixed(
                    Icons.circle,
                    size: 9,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('dhuhrIsPast', defaultValue: false),
                    whenTrue: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                        dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                      ),
                    ),
                    whenFalse: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(
                          AppColors.widgetMutedTintLightArgb,
                        ),
                        dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
                      ),
                    ),
                  ),
                ),
                // Asr
                HWBoolConditional(
                  data: HWBool('asrIsActive', defaultValue: false),
                  whenTrue: HWIcon.fixed(
                    Icons.circle,
                    size: 9,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('asrIsPast', defaultValue: false),
                    whenTrue: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                        dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                      ),
                    ),
                    whenFalse: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(
                          AppColors.widgetMutedTintLightArgb,
                        ),
                        dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
                      ),
                    ),
                  ),
                ),
                // Maghrib
                HWBoolConditional(
                  data: HWBool('maghribIsActive', defaultValue: false),
                  whenTrue: HWIcon.fixed(
                    Icons.circle,
                    size: 9,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('maghribIsPast', defaultValue: false),
                    whenTrue: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                        dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                      ),
                    ),
                    whenFalse: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(
                          AppColors.widgetMutedTintLightArgb,
                        ),
                        dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
                      ),
                    ),
                  ),
                ),
                // Isha
                HWBoolConditional(
                  data: HWBool('ishaIsActive', defaultValue: false),
                  whenTrue: HWIcon.fixed(
                    Icons.circle,
                    size: 9,
                    color: HWColor.themed(
                      light: HWColor.fixed(AppColors.primaryLightArgb),
                      dark: HWColor.fixed(AppColors.widgetAccentDarkArgb),
                    ),
                  ),
                  whenFalse: HWBoolConditional(
                    data: HWBool('ishaIsPast', defaultValue: false),
                    whenTrue: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(AppColors.widgetMutedLightArgb),
                        dark: HWColor.fixed(AppColors.widgetMutedDarkArgb),
                      ),
                    ),
                    whenFalse: HWIcon.fixed(
                      Icons.circle,
                      size: 6,
                      color: HWColor.themed(
                        light: HWColor.fixed(
                          AppColors.widgetMutedTintLightArgb,
                        ),
                        dark: HWColor.fixed(AppColors.widgetMutedTintDarkArgb),
                      ),
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
