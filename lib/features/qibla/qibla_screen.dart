import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/features/qibla/qibla_controller.dart';
import 'package:mawaqit/features/qibla/travel_screen.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/ui_text.dart';

/// Live Qibla compass.
///
/// The bearing is pure maths (see [qiblaBearing]); the only platform-dependent
/// part is the heading stream. When a device has no magnetometer — every desktop
/// and test host — the screen keeps the correct bearing and says so plainly
/// instead of showing a needle that points nowhere.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qiblaControllerProvider);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final hasNeedle = state.hasNeedle;
    final angle = state.needleAngle ?? 0.0;
    final hasSensor = state.status != CompassStatus.unavailable;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        centerTitle: true,
        title: UiText(
          l10n.qiblaTitle,
          type: UiTextType.titleLarge,
          fontWeight: AppWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.huge,
            AppSpacing.sm,
            AppSpacing.huge,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                label: l10n.qiblaTitle,
                description: state.hasLocation
                    ? l10n.qiblaSubtitle(state.locationName)
                    : l10n.travelSetLocation,
                icon: Icons.explore_outlined,
              ),
              AppCard(
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: AppSpacing.offsetXl,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: AppOpacity.hairline,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.navigation_rounded,
                            size: AppIconSize.display,
                            color: hasSensor ? scheme.primary : scheme.outline,
                          ),
                          if (hasNeedle)
                            Transform.rotate(
                              angle: angle * math.pi / 180,
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: AppIconSize.display,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (state.bearing != null)
                      AppPill(
                        label: l10n.qiblaBearing(
                          state.bearing!.round().toString(),
                        ),
                        icon: Icons.explore_outlined,
                      ),
                    if (state.distanceKm != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      UiText(
                        l10n.qiblaDistance(
                          NumberFormat.decimalPattern(
                            Localizations.localeOf(context).languageCode,
                          ).format(state.distanceKm!.round()),
                        ),
                        type: UiTextType.labelLarge,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              if (state.status == CompassStatus.unavailable) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sensors_off_outlined,
                        size: AppIconSize.xl,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UiText(
                              l10n.qiblaSensorUnavailable,
                              type: UiTextType.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            UiText(
                              l10n.qiblaSensorHint,
                              type: UiTextType.labelMedium,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                UiText(
                  state.status == CompassStatus.calibrating
                      ? l10n.qiblaCalibrate
                      : l10n.qiblaCompassHint,
                  type: UiTextType.labelMedium,
                  color: scheme.onSurfaceVariant,
                  textAlign: TextAlign.center,
                ),
                if (state.status == CompassStatus.available) ...[
                  const SizedBox(height: AppSpacing.sm),
                  UiText(
                    l10n.qiblaCalibrate,
                    type: UiTextType.labelMedium,
                    color: scheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.mega),
              AppButton(
                label: l10n.travelTitle,
                icon: Icons.flight_takeoff_outlined,
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TravelScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
