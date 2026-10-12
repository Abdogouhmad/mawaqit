import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:mawaqit/data/services/update_service.dart';

/// The OTA updater decides whether the user sees "what's new", is forced to
/// update, or is left alone. That decision is pure arithmetic over the
/// manifest, so it is pinned here without a network call.
void main() {
  UpdateManifest manifest({
    int code = 1200,
    String name = '0.12.0',
    int? floor,
    bool mandatory = false,
    String apkUrl = 'https://example.com/mawaqit.apk',
  }) => UpdateManifest(
    latestVersionCode: code,
    latestVersionName: name,
    minSupportedVersionCode: floor,
    mandatory: mandatory,
    apkUrl: apkUrl,
  );

  group('UpdateManifest.fromJson', () {
    test('reads every field', () {
      final parsed = UpdateManifest.fromJson({
        'latestVersionCode': 1300,
        'latestVersionName': '0.13.0',
        'minSupportedVersionCode': 3,
        'mandatory': true,
        'releaseNotes': '## [0.13.0]',
        'apkUrl': 'https://example.com/a.apk',
        'sha256': 'abc',
      });

      expect(parsed.latestVersionCode, 1300);
      expect(parsed.latestVersionName, '0.13.0');
      expect(parsed.minSupportedVersionCode, 3);
      expect(parsed.mandatory, isTrue);
      expect(parsed.releaseNotes, '## [0.13.0]');
      expect(parsed.apkUrl, 'https://example.com/a.apk');
      expect(parsed.sha256, 'abc');
    });

    test('defaults absent optional fields instead of throwing', () {
      final parsed = UpdateManifest.fromJson(const {});

      expect(parsed.latestVersionCode, 0);
      expect(parsed.latestVersionName, '');
      expect(parsed.minSupportedVersionCode, isNull);
      expect(parsed.mandatory, isFalse);
      expect(parsed.releaseNotes, '');
      expect(parsed.apkUrl, '');
      expect(parsed.sha256, isNull);
    });
  });

  group('UpdateManifest', () {
    test('isNewerThan compares version codes', () {
      expect(manifest(code: 1200).isNewerThan(1100), isTrue);
      expect(manifest(code: 1200).isNewerThan(1200), isFalse);
      expect(manifest(code: 1200).isNewerThan(1300), isFalse);
    });

    test('isMandatoryFor honours the explicit flag', () {
      expect(
        manifest(code: 1200, mandatory: true).isMandatoryFor(1100),
        isTrue,
      );
    });

    test('isMandatoryFor honours the support floor', () {
      expect(manifest(code: 1200, floor: 1000).isMandatoryFor(900), isTrue);
      expect(manifest(code: 1200, floor: 1000).isMandatoryFor(1000), isFalse);
    });

    test('isMandatoryFor is false when there is nothing newer to install', () {
      expect(
        manifest(code: 1200, mandatory: true).isMandatoryFor(1200),
        isFalse,
      );
    });
  });

  group('UpdateService.check', () {
    const service = UpdateService();

    test('fails when the manifest is missing or malformed', () {
      expect(
        service.check(manifest: null, currentVersionCode: 100),
        UpdateCheckResult.checkFailed,
      );
      expect(
        service.check(manifest: manifest(code: 0), currentVersionCode: 100),
        UpdateCheckResult.checkFailed,
      );
      expect(
        service.check(manifest: manifest(apkUrl: ''), currentVersionCode: 100),
        UpdateCheckResult.checkFailed,
      );
    });

    test('reports up to date when the installed build is current', () {
      expect(
        service.check(manifest: manifest(code: 1200), currentVersionCode: 1200),
        UpdateCheckResult.upToDate,
      );
      expect(
        service.check(manifest: manifest(code: 1200), currentVersionCode: 1300),
        UpdateCheckResult.upToDate,
      );
    });

    test('reports an optional update when newer and supported', () {
      expect(
        service.check(
          manifest: manifest(code: 1200, floor: 1000),
          currentVersionCode: 1100,
        ),
        UpdateCheckResult.updateAvailable,
      );
    });

    test('reports a mandatory update when the build is below the floor', () {
      expect(
        service.check(
          manifest: manifest(code: 1200, floor: 1100),
          currentVersionCode: 900,
        ),
        UpdateCheckResult.updateMandatory,
      );
    });
  });
}
