import '../../domain/entities/shop.dart';

/// Paginated shops list response from API.
class ShopsListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ShopListItemModel> results;

  ShopsListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ShopsListResponse.fromJson(Map<String, dynamic> json) {
    return ShopsListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: ((json['results'] as List<dynamic>?) ?? [])
          .map((item) => ShopListItemModel.fromJson(
            item as Map<String, dynamic>,
          ))
          .toList(),
    );
  }

  /// Get next page number from the `next` URL.
  int? getNextPage() {
    if (next == null) return null;
    try {
      final uri = Uri.parse(next!);
      return int.tryParse(uri.queryParameters['page'] ?? '');
    } catch (e) {
      return null;
    }
  }

  /// Check if there's a next page.
  bool get hasNextPage => next != null;
}

/// Single shop in the list (minimal fields for list display).
class ShopListItemModel {
  final int id;
  final String name;
  final String tagline;
  final String area;
  final String city;
  final String status;
  final double? rating;
  final int ratingCount;
  final String? coverImageUrl;
  final bool isOpenNow;
  final double? distance;
  final int todayBookings;
  final CapacityModel capacity;
  final String? commissionLabel;
  final int servicesCount;

  ShopListItemModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.area,
    required this.city,
    required this.status,
    this.rating,
    required this.ratingCount,
    this.coverImageUrl,
    required this.isOpenNow,
    this.distance,
    required this.todayBookings,
    required this.capacity,
    this.commissionLabel,
    required this.servicesCount,
  });

  factory ShopListItemModel.fromJson(Map<String, dynamic> json) {
    return ShopListItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      coverImageUrl: json['cover_image_url'] as String?,
      isOpenNow: json['is_open_now'] as bool? ?? false,
      distance: (json['distance'] as num?)?.toDouble(),
      todayBookings: json['today_bookings'] as int? ?? 0,
      capacity: CapacityModel.fromJson(
        json['capacity'] as Map<String, dynamic>? ?? {},
      ),
      commissionLabel: json['commission_label'] as String?,
      servicesCount: json['services_count'] as int? ?? 0,
    );
  }

  /// Convert to a simplified Shop domain entity (for list display).
  Shop toDomain() {
    return Shop(
      id: id.toString(),
      name: name,
      area: area,
      ownerName: '',
      ownerPhone: '',
      shopPhone: '',
      address: area,
      rating: rating?.toDouble() ?? 0.0,
      reviews: ratingCount,
      todayBookings: todayBookings,
      cap: capacity.total,
      avgServiceMin: 30,
      active: status == 'active',
      vehicleTypes: [],
      commission: const Commission(mode: CommissionMode.flat, flat: 0),
      bank: const BankDetails(
        accName: '',
        accNo: '',
        ifsc: '',
        upi: '',
        gstin: '',
        pan: '',
      ),
      hours: [],
      photos: coverImageUrl != null ? [coverImageUrl!] : [],
      onboarded: const EditMeta(date: '', by: ''),
      lastEdited: const EditMeta(date: '', by: ''),
      services: [],
      settlement: const Settlement(
        lastSettled: '',
        lifetimePaid: 0,
        pending: [],
        history: [],
      ),
      weekly: [],
      slotCapacityEnabled: false,
      slotCap: 0,
    );
  }
}

/// Capacity info for a shop (used/total).
class CapacityModel {
  final int used;
  final int total;

  CapacityModel({required this.used, required this.total});

  factory CapacityModel.fromJson(Map<String, dynamic> json) {
    return CapacityModel(
      used: json['used'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}
