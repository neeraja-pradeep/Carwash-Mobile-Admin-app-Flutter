import 'package:flutter/foundation.dart';

import '../../../../core/status/booking_status.dart';
import '../../domain/entities/customer.dart';

/// Response from customer list API
class CustomerListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<CustomerApiModel> results;

  CustomerListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      count: _toInt(json['count']),
      next: _toString(json['next']),
      previous: _toString(json['previous']),
      results: (json['results'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => CustomerApiModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Customer card model from the list API response.
class CustomerApiModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? initials;
  final String? email;
  final bool isActive;
  final int bookingsCount;
  final double totalSpent;
  final String? lastBookingDate;

  CustomerApiModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.initials,
    this.email,
    this.isActive = true,
    this.bookingsCount = 0,
    this.totalSpent = 0,
    this.lastBookingDate,
  });

  factory CustomerApiModel.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerApiModel(
        id: _toInt(json['id']),
        fullName: _toString(json['full_name']) ?? '',
        phone: _toString(json['phone']),
        initials: _toString(json['initials']),
        email: _toString(json['email']),
        isActive: _toBool(json['is_active'], fallback: true),
        bookingsCount: _toInt(json['bookings_count']),
        totalSpent: _toDouble(json['total_spent']),
        lastBookingDate: _toString(json['last_booking_date']),
      );
    } catch (e) {
      debugPrint('Error parsing CustomerApiModel: $e');
      rethrow;
    }
  }

  /// Maps a list card into the [Customer] entity used by the UI. Detail-only
  /// fields (addresses, vehicles, history, notes, account age) are left empty;
  /// the detail endpoint fills them when the detail screen opens.
  Customer toEntity() {
    return Customer(
      id: id.toString(),
      name: fullName,
      phone: phone ?? '',
      email: email ?? '',
      joined: '',
      blocked: !isActive,
      blockedReason: '',
      notes: '',
      bookings: bookingsCount,
      spend: totalSpent.round(),
      lastBooking: _formatDate(lastBookingDate),
      accountAge: '',
      addresses: const [],
      vehicles: const [],
      history: const [],
    );
  }
}

/// Customer detail response from GET .../customers/{id}/
class CustomerDetailResponse {
  final int id;
  final String fullName;
  final String? initials;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? createdAt;
  final String? founderNotes;
  final CustomerStatsModel stats;
  final List<CustomerAddressModel> addresses;
  final List<CustomerVehicleModel> vehicles;
  final String? blockReason;
  final String? blockNotes;
  final String? blockedAt;
  final String? blockedByName;

  CustomerDetailResponse({
    required this.id,
    required this.fullName,
    this.initials,
    this.phone,
    this.email,
    this.isActive = true,
    this.createdAt,
    this.founderNotes,
    required this.stats,
    this.addresses = const [],
    this.vehicles = const [],
    this.blockReason,
    this.blockNotes,
    this.blockedAt,
    this.blockedByName,
  });

  factory CustomerDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerDetailResponse(
        id: _toInt(json['id']),
        fullName: _toString(json['full_name']) ?? '',
        initials: _toString(json['initials']),
        phone: _toString(json['phone']),
        email: _toString(json['email']),
        isActive: _toBool(json['is_active'], fallback: true),
        createdAt: _toString(json['created_at']),
        founderNotes: _toString(json['founder_notes']),
        stats: CustomerStatsModel.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {},
        ),
        addresses: (json['addresses'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map((e) => CustomerAddressModel.fromJson(e))
                .toList() ??
            const [],
        vehicles: (json['vehicles'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map((e) => CustomerVehicleModel.fromJson(e))
                .toList() ??
            const [],
        blockReason: _toString(json['block_reason']),
        blockNotes: _toString(json['block_notes']),
        blockedAt: _toString(json['blocked_at']),
        blockedByName: _toString(json['blocked_by_name']),
      );
    } catch (e) {
      debugPrint('Error parsing CustomerDetailResponse: $e');
      rethrow;
    }
  }

  Customer toEntity() {
    return Customer(
      id: id.toString(),
      name: fullName,
      phone: phone ?? '',
      email: email ?? '',
      joined: _formatDate(stats.joined ?? createdAt),
      blocked: !isActive,
      blockedReason: _blockReasonLabel(blockReason),
      notes: founderNotes ?? '',
      bookings: stats.bookingsCount,
      spend: stats.totalSpent.round(),
      lastBooking: _formatDate(stats.lastBookingDate),
      accountAge: stats.age ?? '',
      addresses: addresses.map((a) => a.toEntity()).toList(),
      vehicles: vehicles.map((v) => v.toEntity()).toList(),
      history: const [],
    );
  }
}

/// `stats` block of the customer detail payload.
class CustomerStatsModel {
  final int bookingsCount;
  final double totalSpent;
  final String? lastBookingDate;
  final String? joined;
  final String? age;

  CustomerStatsModel({
    this.bookingsCount = 0,
    this.totalSpent = 0,
    this.lastBookingDate,
    this.joined,
    this.age,
  });

  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      bookingsCount: _toInt(json['bookings_count']),
      totalSpent: _toDouble(json['total_spent']),
      lastBookingDate: _toString(json['last_booking_date']),
      joined: _toString(json['joined']),
      age: _toString(json['age']),
    );
  }
}

/// A saved-address row in the detail payload.
class CustomerAddressModel {
  final int id;
  final String label;
  final String? addressLine;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  CustomerAddressModel({
    required this.id,
    required this.label,
    this.addressLine,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      id: _toInt(json['id']),
      label: _toString(json['label']) ?? 'Address',
      addressLine: _toString(json['address_line']),
      landmark: _toString(json['landmark']),
      city: _toString(json['city']),
      state: _toString(json['state']),
      pincode: _toString(json['pincode']),
      isDefault: _toBool(json['is_default'], fallback: false),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
    );
  }

  SavedAddress toEntity() {
    final parts = <String>[
      if (addressLine != null && addressLine!.isNotEmpty) addressLine!,
      if (landmark != null && landmark!.isNotEmpty) landmark!,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (pincode != null && pincode!.isNotEmpty) pincode!,
    ];
    return SavedAddress(
      id: id,
      label: label,
      text: parts.join(', '),
      isDefault: isDefault,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// A garage-vehicle row in the detail payload.
class CustomerVehicleModel {
  final int id;
  final String? carType;
  final String? brandModel;
  final String? registration;
  final bool isPrimary;
  final int bookingCount;

  CustomerVehicleModel({
    required this.id,
    this.carType,
    this.brandModel,
    this.registration,
    this.isPrimary = false,
    this.bookingCount = 0,
  });

  factory CustomerVehicleModel.fromJson(Map<String, dynamic> json) {
    return CustomerVehicleModel(
      id: _toInt(json['id']),
      carType: _toString(json['car_type']),
      brandModel: _toString(json['brand_model']),
      registration: _toString(json['registration']),
      isPrimary: _toBool(json['is_primary'], fallback: false),
      bookingCount: _toInt(json['booking_count']),
    );
  }

  GarageVehicle toEntity() {
    // brand_model is a single string (e.g. "Hyundai Creta"); split into
    // make/model for the existing GarageVehicle shape.
    final bm = (brandModel ?? '').trim();
    String make = bm;
    String model = '';
    final space = bm.indexOf(' ');
    if (space > 0) {
      make = bm.substring(0, space);
      model = bm.substring(space + 1);
    }
    return GarageVehicle(
      carId: id,
      make: make,
      model: model,
      type: carType ?? '',
      plate: registration ?? '',
      isDefault: isPrimary,
      bookings: bookingCount,
    );
  }
}

/// Custom paginated envelope from GET .../customers/{id}/history/
class CustomerHistoryResponse {
  final int count;
  final int page;
  final int pageSize;
  final String? next;
  final String? previous;
  final List<CustomerHistoryRowModel> results;

  CustomerHistoryResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    this.next,
    this.previous,
    required this.results,
  });

  factory CustomerHistoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerHistoryResponse(
        count: _toInt(json['count']),
        page: _toInt(json['page']),
        pageSize: _toInt(json['page_size']),
        next: _toString(json['next']),
        previous: _toString(json['previous']),
        results: (json['results'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map((e) => CustomerHistoryRowModel.fromJson(e))
                .toList() ??
            const [],
      );
    } catch (e) {
      debugPrint('Error parsing CustomerHistoryResponse: $e');
      return CustomerHistoryResponse(
        count: 0,
        page: 1,
        pageSize: 20,
        results: const [],
      );
    }
  }
}

/// A single booking-history row (carwash or driver/inspection).
class CustomerHistoryRowModel {
  final String reference;
  final String kind;
  final String? appointmentDate;
  final double amount;
  final String status;
  final String? displayStatus;
  final String? shopName;

  CustomerHistoryRowModel({
    required this.reference,
    required this.kind,
    this.appointmentDate,
    this.amount = 0,
    this.status = '',
    this.displayStatus,
    this.shopName,
  });

  factory CustomerHistoryRowModel.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryRowModel(
      reference: _toString(json['reference']) ?? '',
      kind: _toString(json['kind']) ?? 'carwash',
      appointmentDate: _toString(json['appointment_date']),
      amount: _toDouble(json['amount']),
      status: _toString(json['status']) ?? '',
      displayStatus: _toString(json['display_status']),
      shopName: _toString(json['shop_name']),
    );
  }

  CustomerBookingRef toEntity() {
    // Driver/inspection rows have no shop_name; fall back to the kind label.
    final shop = (shopName != null && shopName!.isNotEmpty)
        ? shopName!
        : _kindLabel(kind);
    return CustomerBookingRef(
      id: reference,
      date: _formatDate(appointmentDate),
      shop: shop,
      status: bookingStatusFromKey(status),
      amount: amount.round(),
    );
  }
}

/// Result of a block/unblock action.
class CustomerBlockResponse {
  final int id;
  final bool isActive;
  final String? blockReason;
  final String? blockNotes;
  final String? blockedAt;

  CustomerBlockResponse({
    required this.id,
    required this.isActive,
    this.blockReason,
    this.blockNotes,
    this.blockedAt,
  });

  factory CustomerBlockResponse.fromJson(Map<String, dynamic> json) {
    return CustomerBlockResponse(
      id: _toInt(json['id']),
      isActive: _toBool(json['is_active'], fallback: true),
      blockReason: _toString(json['block_reason']),
      blockNotes: _toString(json['block_notes']),
      blockedAt: _toString(json['blocked_at']),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Like [_toDouble] but keeps `null` distinct from `0` — a coordinate the
/// customer never set must not read as the middle of the Atlantic.
double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

bool _toBool(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
  }
  return fallback;
}

/// Formats an ISO date/datetime string into the UI's `dd-MMM-yyyy` form
/// (e.g. `2026-05-29` → `29-May-2026`). Empty/unparseable → ''.
String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = dt.day.toString().padLeft(2, '0');
  return '$day-${months[dt.month - 1]}-${dt.year}';
}

/// Humanizes a history-row `kind` into a fallback shop/label.
String _kindLabel(String kind) {
  switch (kind) {
    case 'carwash':
      return 'Car Wash';
    case 'driver':
      return 'Driver Hire';
    case 'inspection':
      return 'Inspection';
    default:
      return kind.isEmpty ? 'Booking' : kind;
  }
}

/// Maps the server block-reason enum to a human label for the block alert.
String _blockReasonLabel(String? reason) {
  switch (reason) {
    case 'frequent_no_shows':
      return 'Frequent no-shows';
    case 'abusive_behavior':
      return 'Abusive behavior';
    case 'payment_issues':
      return 'Payment issues';
    case 'fake_bookings':
      return 'Fake bookings';
    case 'other':
      return 'Other';
    default:
      return reason ?? '';
  }
}
