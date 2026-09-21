import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/audio/tone_catalog.dart';

void main() {
  test('byName resolves bundled tones and falls back safely', () {
    expect(ToneCatalog.byName('Adham Al Sharqawe').androidRawResource,
        'adhan_adham_al_sharqawe');
    expect(ToneCatalog.byName('Silent').silent, isTrue);
    expect(
      ToneCatalog.byName('does-not-exist').name,
      ToneCatalog.fallback.name,
    );
  });

  test('device tone slug is stable and resource-safe', () {
    expect(
      const DeviceTone(
        name: 'Ring',
        uri: 'content://media/internal/audio/media/42',
      ).slug,
      '42',
    );
    expect(
      const DeviceTone(name: 'Odd', uri: 'content://media/x/Chime_Sound-2').slug,
      'chimesound2',
    );
  });
}
