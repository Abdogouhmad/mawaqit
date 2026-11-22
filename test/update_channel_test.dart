import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mawaqit/data/models/update_channel.dart';
import 'package:mawaqit/data/models/update_manifest.dart';
import 'package:mawaqit/data/services/update_service.dart';
import 'package:mawaqit/features/settings/update_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The channel choice decides which signed manifest a device trusts, so the
/// resolution, URLs and fail-closed gates are pinned here without a real
/// network call.
void main() {
  const validChecksum =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  UpdateManifest manifest({
    String version = '0.17.0',
    int code = 1700,
    String channel = 'stable',
    bool prerelease = false,
    String name = '0.17.0',
    String url = 'https://example.com/mawaqit.apk',
    String? sha256 = validChecksum,
    int? size,
  }) => UpdateManifest(
    latestVersionName: version,
    latestVersionCode: code,
    channel: channel,
    isPrerelease: prerelease,
    releaseNotes: 'notes',
    apkUrl: url,
    sha256: sha256,
    size: size,
  );

  group('UpdateChannel', () {
    test('missing and unknown values stay on stable', () {
      expect(UpdateChannel.fromStorage(null), UpdateChannel.stable);
      expect(UpdateChannel.fromStorage(''), UpdateChannel.stable);
      expect(UpdateChannel.fromStorage('nightly'), UpdateChannel.stable);
      expect(UpdateChannel.fromStorage('beta'), UpdateChannel.beta);
    });

    test('tryFromStorage rejects unknown manifest channels', () {
      expect(UpdateChannel.tryFromStorage('stable'), UpdateChannel.stable);
      expect(UpdateChannel.tryFromStorage('beta'), UpdateChannel.beta);
      expect(UpdateChannel.tryFromStorage('nightly'), isNull);
    });
  });

  group('compareUpdateVersions', () {
    test('compares cores numerically', () {
      expect(compareUpdateVersions('0.9.0', '0.10.0'), lessThan(0));
      expect(compareUpdateVersions('1.0.0', '0.99.99'), greaterThan(0));
      expect(compareUpdateVersions('1.2.3', '1.2.3'), 0);
    });

    test('a release outranks its pre-releases', () {
      expect(compareUpdateVersions('1.9.0', '1.9.0-beta.1'), greaterThan(0));
      expect(compareUpdateVersions('1.9.0-beta.1', '1.9.0'), lessThan(0));
    });

    test('numeric pre-release identifiers compare numerically', () {
      expect(
        compareUpdateVersions('1.9.0-beta.10', '1.9.0-beta.2'),
        greaterThan(0),
      );
      expect(
        compareUpdateVersions('1.9.0-beta.2', '1.9.0-beta.10'),
        lessThan(0),
      );
    });

    test('ignores build metadata and tolerates malformed input', () {
      expect(compareUpdateVersions('1.2.0+build.1', '1.2.0+build.2'), 0);
      expect(() => compareUpdateVersions('', 'x'), returnsNormally);
    });
  });

  group('channel-aware manifest URL', () {
    test('stable and beta have distinct committed manifests', () {
      const service = UpdateService();
      final at = DateTime.utc(2026, 11, 22, 12);
      expect(
        service.manifestUri(now: at).path,
        '/Abdogouhmad/mawaqit/main/update_manifest.json',
      );
      expect(
        service.manifestUri(channel: UpdateChannel.beta, now: at).path,
        '/Abdogouhmad/mawaqit/main/update_manifest_beta.json',
      );
    });

    test('both channels carry the cache-busting timestamp', () {
      const service = UpdateService();
      final at = DateTime.utc(2026, 11, 22, 12);
      for (final channel in UpdateChannel.values) {
        final uri = service.manifestUri(channel: channel, now: at);
        expect(uri.queryParameters['ts'], at.millisecondsSinceEpoch.toString());
        expect(uri.scheme, 'https');
      }
    });

    test('customManifestUrl overrides both channel URLs', () {
      const service = UpdateService(
        customManifestUrl: 'https://example.com/local.json?token=1',
      );
      final uri = service.manifestUri(channel: UpdateChannel.beta);
      expect(
        uri.toString().startsWith('https://example.com/local.json'),
        isTrue,
      );
      expect(uri.queryParameters['token'], '1');
      expect(uri.queryParameters.containsKey('ts'), isTrue);
    });

    test('fetchManifest requests the selected channel', () async {
      Uri? requested;
      final client = MockClient((request) async {
        requested = request.url;
        return http.Response(
          '{"latestVersionName":"0.17.0","latestVersionCode":1700,'
          '"apkUrl":"https://example.com/a.apk",'
          '"sha256":"$validChecksum","channel":"beta","isPrerelease":true}',
          200,
        );
      });
      final service = UpdateService(httpClient: client);
      final manifest = await service.fetchManifest(channel: UpdateChannel.beta);
      expect(requested!.path, endsWith('/update_manifest_beta.json'));
      expect(manifest!.latestVersionName, '0.17.0');
      expect(manifest.isPrerelease, isTrue);

      Uri? stableRequested;
      final stableClient = MockClient((request) async {
        stableRequested = request.url;
        return http.Response('{}', 200);
      });
      final stableService = UpdateService(httpClient: stableClient);
      await stableService.fetchManifest();
      expect(stableRequested!.path, endsWith('/update_manifest.json'));
    });
  });

  group('check() gates', () {
    const service = UpdateService();

    test('stable refuses a prerelease even with a valid checksum', () {
      expect(
        service.check(
          manifest: manifest(channel: 'beta', prerelease: true),
          currentVersionCode: 1600,
          currentVersionName: '0.16.0',
        ),
        UpdateCheckResult.upToDate,
      );
    });

    test('beta accepts its own prerelease', () {
      expect(
        service.check(
          manifest: manifest(channel: 'beta', prerelease: true),
          currentVersionCode: 1600,
          currentVersionName: '0.16.0',
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.updateAvailable,
      );
    });

    test('beta refuses a manifest that declares itself stable', () {
      expect(
        service.check(
          manifest: manifest(),
          currentVersionCode: 1600,
          currentVersionName: '0.16.0',
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.checkFailed,
      );
    });

    test('an empty beta seed offers no update and is not an error', () {
      final seed = UpdateManifest.fromJson(
        jsonDecode(
          '{"latestVersionName":"","latestVersionCode":0,"apkUrl":"","sha256":"","channel":"beta","isPrerelease":true}',
        ) as Map<String, dynamic>,
      );
      expect(seed.isEmptySeed, isTrue);
      expect(
        service.check(
          manifest: seed,
          currentVersionCode: 1600,
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.upToDate,
      );
    });

    test('a malformed beta manifest still fails closed', () {
      expect(
        service.check(
          manifest: manifest(
            channel: 'beta',
            prerelease: true,
            sha256: 'not-a-hash',
          ),
          currentVersionCode: 1600,
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.checkFailed,
      );
    });

    test('an unknown channel is never installable', () {
      expect(
        service.check(
          manifest: manifest(channel: 'nightly'),
          currentVersionCode: 1600,
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.checkFailed,
      );
    });

    test('equal version codes fall back to semver precedence', () {
      expect(
        service.check(
          manifest: manifest(channel: 'beta'),
          currentVersionCode: 1700,
          currentVersionName: '0.17.0-beta.1',
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.updateAvailable,
      );
      expect(
        service.check(
          manifest: manifest(
            version: '0.17.0-beta.1',
            channel: 'beta',
            prerelease: true,
          ),
          currentVersionCode: 1700,
          currentVersionName: '0.17.0',
          channel: UpdateChannel.beta,
        ),
        UpdateCheckResult.upToDate,
      );
    });
  });

  group('UpdateStore channel persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to stable', () async {
      expect(await UpdateStore().channel(), UpdateChannel.stable);
    });

    test('round-trips beta and ignores unknown stored values', () async {
      final store = UpdateStore();
      await store.saveChannel(UpdateChannel.beta);
      expect(await store.channel(), UpdateChannel.beta);

      SharedPreferences.setMockInitialValues({
        UpdateStore.kUpdateChannelKey: 'nightly',
      });
      expect(await store.channel(), UpdateChannel.stable);
    });

    test('clearing the dismissed version does not lose the channel', () async {
      final store = UpdateStore();
      await store.saveChannel(UpdateChannel.beta);
      await store.saveDismissedVersion('0.17.0-beta.1');
      await store.clearDismissedVersion();
      expect(await store.channel(), UpdateChannel.beta);
      expect(await store.dismissedVersion(), isNull);
    });
  });
}
