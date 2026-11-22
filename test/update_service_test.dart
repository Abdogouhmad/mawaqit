import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:mawaqit/data/services/update_service.dart';

/// The OTA updater decides whether the user sees "what's new", is forced to
/// update, or is left alone. That decision is pure arithmetic over the
/// manifest, so it is pinned here without a network call.
void main() {
  // A release is only installable when its APK is HTTPS and carries a valid
  // 64-hex SHA-256. The check deliberately fails closed otherwise, so every
  // fixture that should be *offered* needs a verifiable checksum.
  const validChecksum =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  UpdateManifest manifest({
    int code = 1200,
    String name = '0.12.0',
    int? floor,
    bool mandatory = false,
    String apkUrl = 'https://example.com/mawaqit.apk',
    String? sha256 = validChecksum,
  }) => UpdateManifest(
    latestVersionCode: code,
    latestVersionName: name,
    minSupportedVersionCode: floor,
    mandatory: mandatory,
    apkUrl: apkUrl,
    sha256: sha256,
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
        'sha256': validChecksum,
        'size': 24 * 1024 * 1024,
        'channel': 'beta',
        'publishedAt': '2026-11-20T10:00:00Z',
      });

      expect(parsed.latestVersionCode, 1300);
      expect(parsed.latestVersionName, '0.13.0');
      expect(parsed.minSupportedVersionCode, 3);
      expect(parsed.mandatory, isTrue);
      expect(parsed.releaseNotes, '## [0.13.0]');
      expect(parsed.apkUrl, 'https://example.com/a.apk');
      expect(parsed.sha256, validChecksum);
      expect(parsed.size, 24 * 1024 * 1024);
      expect(parsed.channel, 'beta');
      expect(parsed.isPrerelease, isTrue);
      expect(parsed.publishedAt, DateTime.utc(2026, 11, 20, 10));
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
      expect(parsed.channel, 'stable');
      expect(parsed.isPrerelease, isFalse);
    });
  });

  group('fail-closed integrity', () {
    test('checksum must be exactly 64 hex digits', () {
      expect(isValidUpdateChecksum(validChecksum), isTrue);
      expect(isValidUpdateChecksum(validChecksum.toUpperCase()), isTrue);
      expect(isValidUpdateChecksum('abc'), isFalse);
      expect(isValidUpdateChecksum(null), isFalse);
      expect(isValidUpdateChecksum('${validChecksum}z'), isFalse);
    });

    test('APK URL must be absolute HTTPS', () {
      expect(isSecureUpdateUrl('https://example.com/a.apk'), isTrue);
      expect(isSecureUpdateUrl('http://example.com/a.apk'), isFalse);
      expect(isSecureUpdateUrl('/local/a.apk'), isFalse);
      expect(isSecureUpdateUrl('not a url'), isFalse);
    });

    test('an unverifiable release is never offered', () {
      const service = UpdateService();
      expect(
        service.check(manifest: manifest(sha256: null), currentVersionCode: 1),
        UpdateCheckResult.checkFailed,
      );
      expect(
        service.check(manifest: manifest(sha256: 'abc'), currentVersionCode: 1),
        UpdateCheckResult.checkFailed,
      );
      expect(
        service.check(
          manifest: manifest(apkUrl: 'http://example.com/a.apk'),
          currentVersionCode: 1,
        ),
        UpdateCheckResult.checkFailed,
      );
    });
  });

  group('UpdateManifest', () {
    test('isNewerThan compares version codes', () {
      expect(manifest().isNewerThan(1100), isTrue);
      expect(manifest().isNewerThan(1200), isFalse);
      expect(manifest().isNewerThan(1300), isFalse);
    });

    test('isMandatoryFor honours the explicit flag', () {
      expect(manifest(mandatory: true).isMandatoryFor(1100), isTrue);
    });

    test('isMandatoryFor honours the support floor', () {
      expect(manifest(floor: 1000).isMandatoryFor(900), isTrue);
      expect(manifest(floor: 1000).isMandatoryFor(1000), isFalse);
    });

    test('isMandatoryFor is false when there is nothing newer to install', () {
      expect(manifest(mandatory: true).isMandatoryFor(1200), isFalse);
    });

    test('formattedSize renders bytes, KB and MB', () {
      expect(
        const UpdateManifest(
          latestVersionCode: 1,
          latestVersionName: '1.0.0',
          apkUrl: 'https://example.com/a.apk',
          size: 512,
        ).formattedSize,
        '512 B',
      );
      expect(
        const UpdateManifest(
          latestVersionCode: 1200,
          latestVersionName: '0.12.0',
          apkUrl: 'https://example.com/a.apk',
          size: 2 * 1024 * 1024,
        ).formattedSize,
        '2.0 MB',
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
        service.check(manifest: manifest(), currentVersionCode: 1200),
        UpdateCheckResult.upToDate,
      );
      expect(
        service.check(manifest: manifest(), currentVersionCode: 1300),
        UpdateCheckResult.upToDate,
      );
    });

    test('reports an optional update when newer and supported', () {
      expect(
        service.check(
          manifest: manifest(floor: 1000),
          currentVersionCode: 1100,
        ),
        UpdateCheckResult.updateAvailable,
      );
    });

    test('reports a mandatory update when the build is below the floor', () {
      expect(
        service.check(manifest: manifest(floor: 1100), currentVersionCode: 900),
        UpdateCheckResult.updateMandatory,
      );
    });
  });
}
