import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mawaqit/data/models/app_settings.dart';

/// Resolved location with human-readable display name.
class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.fromManual,
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final bool fromManual;
}

/// A city matched by name search, ready to pin prayer calculations to.
class CitySearchResult {
  const CitySearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class LocationRepository {
  static const String _latKey = 'resolved_latitude';
  static const String _lngKey = 'resolved_longitude';
  static const String _nameKey = 'resolved_location_name';

  /// Searches for cities by name (e.g. "London", "Casablanca") and returns
  /// up to [limit] candidates with their coordinates.
  ///
  /// Uses the platform geocoder on mobile and falls back to the OpenStreetMap
  /// Nominatim API (which also works on desktop) when the platform geocoder is
  /// unavailable or returns nothing.
  Future<List<CitySearchResult>> searchCities(
    String query, {
    int limit = 5,
  }) async {
    final queryText = query.trim();
    if (queryText.isEmpty) return const [];

    final native = await _searchNative(queryText, limit);
    if (native.isNotEmpty) return native;

    return _searchViaNominatim(queryText, limit);
  }

  Future<List<CitySearchResult>> _searchNative(String query, int limit) async {
    try {
      final locations = await Geocoding().locationFromAddress(query);
      final results = <CitySearchResult>[];
      for (final location in locations.take(limit)) {
        results.add(
          CitySearchResult(
            name: await _displayNameFor(
              location.latitude,
              location.longitude,
              fallback: _titleCase(query),
            ),
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Online fallback via OpenStreetMap Nominatim. Returns close-name matches
  /// for the query; throws [CitySearchRateLimitedException] on 429.
  Future<List<CitySearchResult>> _searchViaNominatim(
    String query,
    int limit,
  ) async {
    final client = HttpClient()
      ..userAgent = 'MawaqitPrayerApp/1.0 (prayer clock; dev build)';
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '$limit',
        'addressdetails': '0',
      });
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.refererHeader, 'https://mawaqit.app');
      final response = await request.close();
      if (response.statusCode == 429) {
        throw const CitySearchRateLimitedException();
      }
      if (response.statusCode != 200) return const [];

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];

      final results = <CitySearchResult>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final name = entry['display_name'];
        if (name is! String || name.isEmpty) continue;
        final lat = double.tryParse('${entry['lat']}');
        final lon = double.tryParse('${entry['lon']}');
        if (lat == null || lon == null) continue;
        results.add(
          CitySearchResult(name: name, latitude: lat, longitude: lon),
        );
        if (results.length >= limit) break;
      }
      return results;
    } on CitySearchRateLimitedException {
      rethrow;
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  /// Resolves coordinates from settings: an explicitly chosen city wins,
  /// otherwise GPS (with the last cached fix as offline fallback).
  Future<ResolvedLocation> resolve({
    required AppSettings settings,
    LocationPermission? grantedPermission,
  }) async {
    if (settings.locationMode == LocationMode.city &&
        settings.hasCityCoordinates) {
      return ResolvedLocation(
        latitude: settings.cityLatitude!,
        longitude: settings.cityLongitude!,
        displayName: settings.cityName ?? 'City',
        fromManual: true,
      );
    }

    final permission = grantedPermission ?? await _ensurePermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      final cached = await _cached();
      if (cached != null) return cached;
      throw LocationPermissionException(permission.toString());
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      final cached = await _cached();
      if (cached != null) return cached;
      throw const LocationServiceDisabledException();
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    var name = 'Current location';
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
        final country = (p.country ?? '').trim();
        name = [city, country].where((e) => e.isNotEmpty).join(', ');
        if (name.isNotEmpty) _cache(pos.latitude, pos.longitude, name);
      }
    } catch (_) {
      _cache(pos.latitude, pos.longitude, name);
    }

    return ResolvedLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      displayName: name,
      fromManual: false,
    );
  }

  Future<String> _displayNameFor(
    double latitude,
    double longitude, {
    required String fallback,
  }) async {
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
        final country = (p.country ?? '').trim();
        final name = [city, country].where((e) => e.isNotEmpty).join(', ');
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}
    return fallback;
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<LocationPermission> _ensurePermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return permission;
    }
    return Geolocator.requestPermission();
  }

  /// Static, plugin-free read used by background isolates.
  static Future<ResolvedLocation?> cached() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final name = prefs.getString(_nameKey);
    if (lat == null || lng == null || name == null) return null;
    return ResolvedLocation(
      latitude: lat,
      longitude: lng,
      displayName: name,
      fromManual: false,
    );
  }

  Future<ResolvedLocation?> _cached() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final name = prefs.getString(_nameKey);
    if (lat == null || lng == null || name == null) return null;
    return ResolvedLocation(
      latitude: lat,
      longitude: lng,
      displayName: name,
      fromManual: false,
    );
  }

  void _cache(double latitude, double longitude, String name) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble(_latKey, latitude);
      prefs.setDouble(_lngKey, longitude);
      prefs.setString(_nameKey, name);
    });
  }
}

class LocationPermissionException implements Exception {
  const LocationPermissionException(this.raw);
  final String raw;
  @override
  String toString() => 'Location permission is required to auto-locate.';
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
  @override
  String toString() => 'Location services are turned off.';
}

class CitySearchRateLimitedException implements Exception {
  const CitySearchRateLimitedException();
  @override
  String toString() => 'Too many search requests. Wait a moment and retry.';
}
