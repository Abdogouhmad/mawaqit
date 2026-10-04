import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/core/const/pref_keys.dart';
import 'package:mawaqit/core/ui/theme/app_colors.dart';
import 'package:mawaqit/core/ui/theme/app_theme.dart';
import 'package:mawaqit/data/models/app_settings.dart';
import 'package:mawaqit/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('palette persistence', () {
    test('defaults to emerald for a fresh install', () async {
      expect((await SettingsRepository().load()).palette, AppPalette.emerald);
    });

    test('round-trips every palette through preferences', () async {
      for (final palette in AppPalette.values) {
        SharedPreferences.setMockInitialValues({});
        final repo = SettingsRepository();
        await repo.save((await repo.load()).copyWith(palette: palette));

        // A *fresh* repository, so the value has demonstrably come back out of
        // storage rather than still sitting in a field.
        expect((await SettingsRepository().load()).palette, palette);
      }
    });

    test('an unknown stored palette falls back to emerald', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.appSettings: '{"palette":"chartreuse"}',
      });
      expect((await SettingsRepository().load()).palette, AppPalette.emerald);
    });

    test(
      'a corrupt settings blob yields defaults instead of throwing',
      () async {
        // The blob is written by one version of the app and read by the next. A
        // parse failure must not brick the app on launch.
        SharedPreferences.setMockInitialValues({
          PrefKeys.appSettings: 'not json at all',
        });
        final settings = await SettingsRepository().load();
        expect(settings.palette, AppPalette.emerald);
        expect(settings.reduceMotion, isFalse);
      },
    );

    test('a blob from before the new fields existed still loads', () async {
      // The pre-1.0 shape: no palette, no reduce-transparency, no reduce-motion.
      SharedPreferences.setMockInitialValues({
        PrefKeys.appSettings: '{"language":"arabic","themeMode":"dark"}',
      });
      final settings = await SettingsRepository().load();

      expect(settings.language, AppLanguage.arabic);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.palette, AppPalette.emerald);
      expect(settings.reduceTransparency, isFalse);
      expect(settings.reduceMotion, isFalse);
    });
  });

  group('accessibility flags', () {
    test('default to off, so the frosted bar is the out-of-the-box look', () {
      const defaults = AppSettings();
      expect(defaults.reduceTransparency, isFalse);
      expect(defaults.reduceMotion, isFalse);
    });

    test('persist independently of each other', () async {
      final repo = SettingsRepository();
      final base = await repo.load();

      await repo.save(base.copyWith(reduceTransparency: true));
      final afterSave = await repo.load();
      expect(afterSave.reduceTransparency, isTrue);
      expect(
        afterSave.reduceMotion,
        isFalse,
        reason: 'turning one flag on must not imply the other',
      );

      final reloaded = await SettingsRepository().load();
      expect(reloaded.reduceTransparency, isTrue);
      expect(reloaded.reduceMotion, isFalse);
    });
  });

  group('palette seeds', () {
    test('every palette has a distinct light and dark seed', () {
      // Two palettes sharing a seed would render as two identical swatches in
      // the picker, and the control would look broken.
      final light = AppPalette.values
          .map((p) => p.lightSeed.toARGB32())
          .toSet();
      final dark = AppPalette.values.map((p) => p.darkSeed.toARGB32()).toSet();
      expect(light.length, AppPalette.values.length);
      expect(dark.length, AppPalette.values.length);
    });

    test('emerald is the brand seed from feat.md', () {
      expect(AppPalette.emerald.lightSeed, AppColors.emeraldSeed);
      expect(AppPalette.emerald.lightSeed, const Color(0xFF0F5C4A));
    });

    test('storage keys round-trip', () {
      for (final palette in AppPalette.values) {
        expect(AppPalette.fromStorageKey(palette.storageKey), palette);
      }
      expect(AppPalette.fromStorageKey(null), AppPalette.emerald);
      expect(AppPalette.fromStorageKey('nope'), AppPalette.emerald);
    });
  });

  group('theme derivation', () {
    test('each palette yields a different primary', () {
      final primaries = AppPalette.values
          .map((p) => AppTheme.light(palette: p).colorScheme.primary.toARGB32())
          .toSet();
      expect(primaries.length, AppPalette.values.length);
    });

    test('light and dark differ for the same palette', () {
      for (final palette in AppPalette.values) {
        expect(
          AppTheme.light(palette: palette).colorScheme.primary,
          isNot(AppTheme.dark(palette: palette).colorScheme.primary),
          reason: '$palette',
        );
      }
    });

    test('emerald light primary is the brand colour', () {
      expect(
        AppTheme.light(palette: AppPalette.emerald).colorScheme.primary,
        AppColors.primaryEmerald,
      );
    });

    test('each palette yields a different primary container', () {
      // `primaryContainer` is the fill behind the selected nav pill. While it
      // was hardcoded to emerald, picking sage or midnight left the bar on
      // green and the picker looked like it had done nothing.
      for (final scheme in [
        (brightness: 'light', build: AppTheme.light),
        (brightness: 'dark', build: AppTheme.dark),
      ]) {
        final containers = AppPalette.values
            .map(
              (p) => scheme
                  .build(palette: p)
                  .colorScheme
                  .primaryContainer
                  .toARGB32(),
            )
            .toSet();
        expect(
          containers.length,
          AppPalette.values.length,
          reason:
              'primaryContainer must differ per palette in '
              '${scheme.brightness}',
        );
      }
    });

    test('the primary container pair stays legible in every palette', () {
      // Guards the hand-tuned pairs: content sitting on the fill has to be the
      // lighter of the two in dark mode and the darker in light mode, or the
      // selected tab's icon and label vanish into the pill.
      for (final palette in AppPalette.values) {
        for (final (brightness, scheme) in [
          (Brightness.light, AppTheme.light(palette: palette).colorScheme),
          (Brightness.dark, AppTheme.dark(palette: palette).colorScheme),
        ]) {
          final fill = scheme.primaryContainer.computeLuminance();
          final content = scheme.onPrimaryContainer.computeLuminance();
          expect(
            fill,
            isNot(closeTo(content, 0.05)),
            reason: '$palette $brightness: fill and content are the same tone',
          );
          if (brightness == Brightness.light) {
            expect(fill, greaterThan(content), reason: '$palette light');
          } else {
            expect(content, greaterThan(fill), reason: '$palette dark');
          }
        }
      }
    });
  });
}
