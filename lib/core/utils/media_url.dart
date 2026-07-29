import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Turns whatever the API hands back for a media field into something
/// `NetworkImage` can actually fetch.
///
/// The backend is inconsistent about this: seeded rows carry a full
/// `https://…` URL, but freshly uploaded BunnyCDN files come back as a bare
/// host + path (`car-wash.b-cdn.net/promotions/ab12.webp`). A URI with no
/// scheme has no host either, so the image loader rejects it outright and the
/// picture silently never appears.
///
/// Returns null for null/empty input so callers can branch on "no image".
String? resolveMediaUrl(String? raw) {
  final url = raw?.trim() ?? '';
  if (url.isEmpty) return null;

  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  // Protocol-relative — inherit https rather than the page scheme.
  if (url.startsWith('//')) return 'https:$url';

  // Server-relative (e.g. Django MEDIA) — resolve against the API host.
  if (url.startsWith('/')) {
    final base = dotenv.maybeGet('API_BASE_URL') ?? '';
    if (base.isEmpty) return url;
    final host = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$host$url';
  }

  // Bare CDN host + path — the shape BunnyCDN uploads come back as.
  return 'https://$url';
}
