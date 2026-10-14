import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/services/muted_prayers_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts empty', () async {
    expect(await MutedPrayersStore().load(), isEmpty);
  });

  test('muting one occurrence persists and survives a fresh store', () async {
    final ids = await MutedPrayersStore().setMuted('2026-09-21_maghrib', true);
    expect(ids, {'2026-09-21_maghrib'});
    // A new instance reads the same file, which is also what native reads.
    expect(await MutedPrayersStore().load(), {'2026-09-21_maghrib'});
  });

  test('unmuting removes only that occurrence', () async {
    final store = MutedPrayersStore();
    await store.setMuted('2026-09-21_maghrib', true);
    await store.setMuted('2026-09-21_isha', true);

    final ids = await store.setMuted('2026-09-21_maghrib', false);

    expect(ids, {'2026-09-21_isha'});
  });

  test('unrelated preference keys are ignored', () async {
    SharedPreferences.setMockInitialValues({
      'muted_prayer_2026-09-21_fajr': true,
      'app_settings_v1': '{"themeMode":"dark"}',
      'muted_other_2026-09-21_fajr': true, // wrong prefix
      'muted_prayer_2026-09-21_dhuhr': false, // present but not muted
    });

    expect(await MutedPrayersStore().load(), {'2026-09-21_fajr'});
  });
}
