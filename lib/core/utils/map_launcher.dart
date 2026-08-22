import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform, debugPrint;
import 'package:url_launcher/url_launcher.dart';

/// Opens the device's map app on a location, preferring a pin dropped on
/// [latitude]/[longitude] and falling back to searching [address] when the
/// coordinates are missing. [label] names the pin where the platform supports
/// it.
///
/// Returns false when there is nothing to show or no app could handle the
/// request, leaving the message to the caller.
///
/// Prefer this over hand-rolled URIs. `https://www.google.com/maps?q=lat,lng`
/// treats its query as a *search*, so Maps often settles on a named place near
/// the point instead of the point itself — the pickup pin landed on a
/// neighbouring business. `geo:` centres the map but marks nothing, and iOS
/// does not handle `geo:` at all.
Future<bool> launchMapPin({
  double? latitude,
  double? longitude,
  String label = '',
  String address = '',
}) async {
  // 0,0 is how the booking parsers spell "no coordinates given" — and it is a
  // real point in the Atlantic, so it must never be treated as a location.
  final hasCoords = latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);
  final trimmedAddress = address.trim();
  if (!hasCoords && trimmedAddress.isEmpty) return false;

  final trimmedLabel = label.trim();
  final pinLabel = Uri.encodeComponent(
    trimmedLabel.isEmpty ? 'Location' : trimmedLabel,
  );

  final List<Uri> candidates;
  if (hasCoords) {
    final coords = '$latitude,$longitude';
    candidates = [
      if (defaultTargetPlatform == TargetPlatform.iOS)
        Uri.parse('https://maps.apple.com/?q=$pinLabel&ll=$coords')
      else
        Uri.parse('geo:$coords?q=$coords($pinLabel)'),
      // Last resort for a device with no map app: the documented Maps URL form,
      // which resolves to the exact coordinate rather than searching for it.
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$coords'),
    ];
  } else {
    // No coordinates to pin, so this genuinely is a search. Hand the address to
    // the map app and let it geocode.
    final query = Uri.encodeComponent(trimmedAddress);
    candidates = [
      if (defaultTargetPlatform == TargetPlatform.iOS)
        Uri.parse('https://maps.apple.com/?q=$query')
      else
        Uri.parse('geo:0,0?q=$query'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
    ];
  }

  for (final uri in candidates) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('Could not launch maps with $uri: $e');
    }
  }
  return false;
}
