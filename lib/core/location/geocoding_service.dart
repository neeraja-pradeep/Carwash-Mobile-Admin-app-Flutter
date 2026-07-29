import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart' as native;
import 'package:http/http.dart' as http;

import '../utils/logger.dart';
import 'geo_place.dart';

/// Forward (text → coordinates) and reverse (coordinates → address) geocoding
/// for the map picker.
///
/// Reverse lookups try the **platform geocoder** first (`geocoding` package —
/// Android `Geocoder` / iOS `CLGeocoder`): it needs no API key, has no rate
/// limit, and is usually the most accurate. It is however unavailable on many
/// emulators and on devices without Google Play services, and it often omits
/// the postal code — so anything it leaves blank is topped up from
/// **Nominatim** (OpenStreetMap), which also backs the search box.
///
/// Nominatim's usage policy caps callers at ~1 request/second and requires an
/// identifying User-Agent. The picker debounces typing and only reverse-geocodes
/// when the map settles, which keeps us well inside that budget.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _userAgent = 'DriveyAdmin/1.0 (shop-location-picker)';

  /// Results are biased to India — the whole app models postal codes as 6-digit
  /// Indian PINs. Widen or drop this when the platform launches elsewhere.
  static const _countryCodes = 'in';

  static const _timeout = Duration(seconds: 12);

  /// Resolves [query] to a ranked list of candidate places for the search box.
  /// Returns an empty list when nothing matches or the lookup fails — the
  /// picker still works by dragging the map, so a failed search is not an error
  /// worth surfacing as a dialog.
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.https(_nominatimHost, '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      'countrycodes': _countryCodes,
    });

    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_placeFromNominatim)
          .whereType<GeoPlace>()
          .toList();
    } catch (e) {
      AppLogger.error('Place search failed', error: e);
      return const [];
    }
  }

  /// Resolves [latitude] / [longitude] to an address.
  ///
  /// Always returns a place holding the given coordinates — the address fields
  /// are simply left empty when no geocoder could resolve them, so the admin can
  /// still type the address by hand after picking the point.
  Future<GeoPlace> reverse(double latitude, double longitude) async {
    var result = GeoPlace(latitude: latitude, longitude: longitude);

    final fromDevice = await _reverseNative(latitude, longitude);
    if (fromDevice != null) result = result.mergeMissing(fromDevice);

    // Top up whatever the platform geocoder left blank — most often the pincode.
    if (!result.hasAddress || !result.hasPincode) {
      final fromOsm = await _reverseNominatim(latitude, longitude);
      if (fromOsm != null) result = result.mergeMissing(fromOsm);
    }

    return result;
  }

  Future<GeoPlace?> _reverseNative(double latitude, double longitude) async {
    try {
      final marks = await native
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(_timeout);
      if (marks.isEmpty) return null;
      final m = marks.first;

      final line = <String?>[
        m.name,
        m.street,
        m.subLocality,
        m.locality,
        m.administrativeArea,
      ];

      return GeoPlace(
        latitude: latitude,
        longitude: longitude,
        address: _joinUnique(line),
        pincode: m.postalCode ?? '',
        city: m.locality ?? '',
        state: m.administrativeArea ?? '',
      );
    } catch (e) {
      // Expected on emulators and Play-services-less devices; Nominatim covers it.
      AppLogger.debug('Platform reverse geocode unavailable: $e');
      return null;
    }
  }

  Future<GeoPlace?> _reverseNominatim(double latitude, double longitude) async {
    final uri = Uri.https(_nominatimHost, '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
    });

    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return _placeFromNominatim(decoded);
    } catch (e) {
      AppLogger.error('Nominatim reverse geocode failed', error: e);
      return null;
    }
  }

  /// Maps one Nominatim `/search` or `/reverse` record onto a [GeoPlace].
  /// Returns null when the record carries no usable coordinates.
  GeoPlace? _placeFromNominatim(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final address = json['address'];
    final parts = address is Map<String, dynamic> ? address : const {};

    String field(List<String> keys) {
      for (final key in keys) {
        final value = parts[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    // `display_name` ends with ", <pincode>, India" — drop the tail so the
    // Address field holds the street/locality part the form asks for.
    final display = '${json['display_name'] ?? ''}';
    final country = field(const ['country']);
    final pincode = field(const ['postcode']);
    final line = display
        .split(',')
        .map((s) => s.trim())
        .where((s) =>
            s.isNotEmpty &&
            s != country &&
            s != pincode &&
            !RegExp(r'^\d{6}$').hasMatch(s))
        .toList();

    return GeoPlace(
      latitude: lat,
      longitude: lon,
      address: line.join(', '),
      pincode: pincode,
      city: field(const ['city', 'town', 'village', 'suburb', 'county']),
      state: field(const ['state']),
    );
  }

  /// Joins non-empty, non-repeating address components with `, `. The platform
  /// geocoder frequently returns the same value for `name` and `street`.
  String _joinUnique(List<String?> parts) {
    final seen = <String>{};
    final kept = <String>[];
    for (final part in parts) {
      final value = part?.trim() ?? '';
      if (value.isEmpty) continue;
      if (!seen.add(value.toLowerCase())) continue;
      kept.add(value);
    }
    return kept.join(', ');
  }

  void dispose() => _client.close();
}
