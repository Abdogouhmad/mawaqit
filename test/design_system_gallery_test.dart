import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/core/ui/theme/app_tokens.dart';
import 'package:mawaqit/core/ui/widgets/empty_state.dart';
import 'package:mawaqit/l10n/gen/app_localizations.dart';
import 'package:mawaqit/shared/components/info_row.dart';
import 'package:mawaqit/shared/components/section_header.dart';
import 'package:mawaqit/shared/components/settings_group.dart';
import 'package:mawaqit/shared/components/settings_row.dart';
import 'package:mawaqit/shared/ui/app_button.dart';
import 'package:mawaqit/shared/ui/app_card.dart';
import 'package:mawaqit/shared/ui/app_icon_button.dart';
import 'package:mawaqit/shared/ui/app_list_row.dart';
import 'package:mawaqit/shared/ui/app_loading_state.dart';
import 'package:mawaqit/shared/ui/app_navigation_bar.dart';
import 'package:mawaqit/shared/ui/app_pill.dart';
import 'package:mawaqit/shared/ui/icon_badge.dart';
import 'package:mawaqit/shared/ui/segmented_control.dart';

/// Widget-level gallery for the 0.17 primitive set.
///
/// Goldens would be brittle across the three bundled font families and Flutter
/// upgrades, so this pins the properties that actually regress: every primitive
/// builds, stays unclipped and keeps its direction at narrow widths, large text,
/// both brightnesses and both layout directions.
void main() {
  const galleryKey = Key('design-gallery');

  for (final width in [360.0, 388.0]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'primitives at ${width.toInt()}dp, ${locale.languageCode}, '
            '${brightness.name}, ${scale}x',
            (tester) async {
              tester.view.physicalSize = Size(width, 900) * 3;
              tester.view.devicePixelRatio = 3;
              addTearDown(tester.view.reset);

              await _pumpGallery(
                tester,
                locale: locale,
                brightness: brightness,
                scale: scale,
              );

              expect(
                tester.takeException(),
                isNull,
                reason: 'overflow or layout error in the primitive gallery',
              );

              final direction = Directionality.of(
                tester.element(find.byKey(galleryKey)),
              );
              expect(
                direction,
                locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              );

              for (final key in _primitiveKeys) {
                expect(find.byKey(key), findsOneWidget, reason: '$key');
              }
              expect(find.byType(AppCard), findsWidgets);
              expect(find.byType(AppListRow), findsWidgets);
              expect(find.byType(AppButton), findsWidgets);
            },
          );
        }
      }
    }
  }

  testWidgets('interactive primitives report their selection', (tester) async {
    await _pumpGallery(
      tester,
      locale: const Locale('en'),
      brightness: Brightness.light,
      scale: 1,
    );

    var iconTaps = 0;
    var buttonTaps = 0;
    String? segment;
    int? tab;

    // Re-pump with fresh callbacks so the assertions cover the gestures rather
    // than the static layout above.
    await tester.pumpWidget(
      _galleryApp(
        locale: const Locale('en'),
        brightness: Brightness.light,
        scale: 1,
        onIconTap: () => iconTaps++,
        onButtonTap: () => buttonTaps++,
        onSegmentChanged: (value) => segment = value,
        onTabSelected: (index) => tab = index,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('gallery-icon-button')));
    await tester.tap(find.byKey(const Key('gallery-icon-button')));
    await tester.ensureVisible(find.byKey(const Key('gallery-button')));
    await tester.tap(find.byKey(const Key('gallery-button')));
    await tester.ensureVisible(find.text('Two'));
    await tester.tap(find.text('Two'));
    await tester.tap(find.byKey(const Key('gallery-nav')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(iconTaps, 1);
    expect(buttonTaps, 1);
    expect(segment, 'b');
    expect(tab, isNotNull);
  });
}

const List<Key> _primitiveKeys = [
  Key('gallery-card'),
  Key('gallery-section'),
  Key('gallery-list-row'),
  Key('gallery-badge'),
  Key('gallery-settings-row'),
  Key('gallery-settings-group'),
  Key('gallery-pill'),
  Key('gallery-detail-row'),
  Key('gallery-empty'),
  Key('gallery-loading'),
  Key('gallery-icon-button'),
  Key('gallery-segmented'),
  Key('gallery-button'),
  Key('gallery-nav'),
];

Future<void> _pumpGallery(
  WidgetTester tester, {
  required Locale locale,
  required Brightness brightness,
  required double scale,
}) async {
  await tester.pumpWidget(
    _galleryApp(locale: locale, brightness: brightness, scale: scale),
  );
  await tester.pump();
}

Widget _galleryApp({
  required Locale locale,
  required Brightness brightness,
  required double scale,
  VoidCallback? onIconTap,
  VoidCallback? onButtonTap,
  ValueChanged<String>? onSegmentChanged,
  ValueChanged<int>? onTabSelected,
}) {
  final theme = brightness == Brightness.light
      ? AppTheme.light(arabic: locale.languageCode == 'ar')
      : AppTheme.dark(arabic: locale.languageCode == 'ar');

  return MaterialApp(
    theme: theme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: KeyedSubtree(
      key: const Key('design-gallery'),
      child: _Gallery(
        onIconTap: onIconTap,
        onButtonTap: onButtonTap,
        onSegmentChanged: onSegmentChanged,
        onTabSelected: onTabSelected,
      ),
    ),
  );
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    this.onIconTap,
    this.onButtonTap,
    this.onSegmentChanged,
    this.onTabSelected,
  });

  final VoidCallback? onIconTap;
  final VoidCallback? onButtonTap;
  final ValueChanged<String>? onSegmentChanged;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              key: Key('gallery-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    key: Key('gallery-section'),
                    icon: Icons.tune,
                    label: 'Section',
                    description: 'A quiet group of controls',
                  ),
                  AppListRow(
                    key: Key('gallery-list-row'),
                    leading: IconBadge(
                      key: Key('gallery-badge'),
                      icon: Icons.list_alt,
                    ),
                    title: 'List row',
                    subtitle: 'Title and subtitle',
                    trailing: AppPill(label: 'On'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SettingsGroup(
              key: Key('gallery-settings-group'),
              children: [
                SettingsRow(
                  key: Key('gallery-settings-row'),
                  icon: Icons.settings_outlined,
                  title: 'Settings row',
                  subtitle: 'Shared leading badge',
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppPill(key: Key('gallery-pill'), label: 'Status'),
            const SizedBox(height: AppSpacing.xl),
            const InfoRow(
              key: Key('gallery-detail-row'),
              label: 'Detail',
              value: 'Value',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: AppSpacing.xl),
            const EmptyState(
              key: Key('gallery-empty'),
              icon: Icons.inbox_outlined,
              title: 'Nothing here',
              body: 'A calm empty state',
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppLoadingState(
              key: Key('gallery-loading'),
              label: 'Loading',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppIconButton(
              key: const Key('gallery-icon-button'),
              icon: Icons.info_outline,
              tooltip: 'Info',
              onPressed: onIconTap ?? () {},
            ),
            const SizedBox(height: AppSpacing.xl),
            SegmentedControl<String>(
              key: const Key('gallery-segmented'),
              options: const [('a', 'One'), ('b', 'Two'), ('c', 'Three')],
              value: 'a',
              icons: const [Icons.looks_one, Icons.looks_two, Icons.looks_3],
              onChanged: onSegmentChanged ?? (_) {},
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('gallery-button'),
              label: 'Action',
              icon: Icons.check,
              onPressed: onButtonTap ?? () {},
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        key: const Key('gallery-nav'),
        selectedIndex: 0,
        onDestinationSelected: onTabSelected ?? (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Times',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
