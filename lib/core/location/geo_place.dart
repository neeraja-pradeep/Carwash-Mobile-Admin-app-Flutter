/// A resolved point on the map: coordinates plus the postal address the
/// geocoder returned for them.
///
/// Produced by `GeocodingService` (forward search and reverse lookup) and
/// consumed by the map picker. Every text field may be empty when the geocoder
/// could not resolve it — only [latitude] / [longitude] are always meaningful.
class GeoPlace {
  const GeoPlace({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.pincode = '',
    this.city = '',
    this.state = '',
  });

  final double latitude;
  final double longitude;

  /// Single-line human-readable address (street, locality, city).
  final String address;

  /// Postal code — a 6-digit PIN in India. Empty when unresolved.
  final String pincode;

  final String city;
  final String state;

  /// `9.498100, 76.338500` — shown under the picked address as proof of the
  /// exact coordinates that will be sent to the backend.
  String get coordsLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  bool get hasAddress => address.trim().isNotEmpty;
  bool get hasPincode => pincode.trim().isNotEmpty;

  GeoPlace copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? pincode,
    String? city,
    String? state,
  }) {
    return GeoPlace(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  /// Fills this place's empty text fields from [other]. Used to top up a native
  /// geocoder result that resolved the street but not the pincode.
  GeoPlace mergeMissing(GeoPlace other) {
    return copyWith(
      address: hasAddress ? address : other.address,
      pincode: hasPincode ? pincode : other.pincode,
      city: city.isNotEmpty ? city : other.city,
      state: state.isNotEmpty ? state : other.state,
    );
  }
}
