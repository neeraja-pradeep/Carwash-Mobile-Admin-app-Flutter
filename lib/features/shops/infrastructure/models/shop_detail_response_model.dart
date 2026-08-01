import '../../../../core/utils/media_url.dart';
import '../../domain/entities/shop.dart';

/// Shop detail response from GET /api/shop/v1/shops/{id}/
class ShopDetailResponseModel {
  final int id;
  final String name;
  final String tagline;
  final String status;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double? distance;
  final String phone;
  final String? coverImageUrl;
  final String? normalImage1Url;
  final String? normalImage2Url;
  final String? normalImage3Url;
  final String? normalImage4Url;
  final double rating;
  final int ratingCount;
  final bool isOpenNow;
  final String ownerName;
  final String ownerPhone;
  final int todayBookings;
  final CapacityDetailModel capacity;
  final int? avgServiceMinutes;
  final List<OperatingHourModel> operatingHours;
  final HolidayModel? nextHoliday;
  final OperationalConfigModel operationalConfig;
  final SettlementModel? settlement;
  final String onboardedAt;
  final String? onboardedByName;
  final String? lastEditedByName;
  final String updatedAt;

  ShopDetailResponseModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.status,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.distance,
    required this.phone,
    this.coverImageUrl,
    this.normalImage1Url,
    this.normalImage2Url,
    this.normalImage3Url,
    this.normalImage4Url,
    required this.rating,
    required this.ratingCount,
    required this.isOpenNow,
    required this.ownerName,
    required this.ownerPhone,
    required this.todayBookings,
    required this.capacity,
    this.avgServiceMinutes,
    required this.operatingHours,
    this.nextHoliday,
    required this.operationalConfig,
    this.settlement,
    required this.onboardedAt,
    this.onboardedByName,
    this.lastEditedByName,
    required this.updatedAt,
  });

  factory ShopDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble(),
      phone: json['phone'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      normalImage1Url: json['normal_image1_url'] as String?,
      normalImage2Url: json['normal_image2_url'] as String?,
      normalImage3Url: json['normal_image3_url'] as String?,
      normalImage4Url: json['normal_image4_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      isOpenNow: json['is_open_now'] as bool? ?? false,
      ownerName: json['owner_name'] as String? ?? '',
      ownerPhone: json['owner_phone'] as String? ?? '',
      todayBookings: json['today_bookings'] as int? ?? 0,
      capacity: CapacityDetailModel.fromJson(
        json['capacity'] as Map<String, dynamic>? ?? {},
      ),
      avgServiceMinutes: json['avg_service_minutes'] as int?,
      operatingHours: ((json['operating_hours'] as List<dynamic>?) ?? [])
          .map((h) => OperatingHourModel.fromJson(h as Map<String, dynamic>))
          .toList(),
      nextHoliday: json['next_holiday'] != null
          ? HolidayModel.fromJson(json['next_holiday'] as Map<String, dynamic>)
          : null,
      operationalConfig: OperationalConfigModel.fromJson(
        json['operational_config'] as Map<String, dynamic>? ?? {},
      ),
      settlement: json['settlement'] != null
          ? SettlementModel.fromJson(json['settlement'] as Map<String, dynamic>)
          : null,
      onboardedAt: json['onboarded_at'] as String? ?? '',
      onboardedByName: json['onboarded_by_name'] as String?,
      lastEditedByName: json['last_edited_by_name'] as String?,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  /// Convert to domain Shop entity.
  Shop toDomain() {
    return Shop(
      id: id.toString(),
      name: name,
      area: address,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      shopPhone: phone,
      address: address,
      rating: rating,
      reviews: ratingCount,
      todayBookings: todayBookings,
      cap: capacity.total,
      avgServiceMin: avgServiceMinutes ?? 30,
      active: status == 'active',
      vehicleTypes: operationalConfig.vehicleTypes
          .where((v) => v.supported)
          .map(_displayVehicleType)
          .toList(),
      commission: _parseCommission(settlement?.commission),
      bank: _parseBank(settlement?.bank),
      hours: _parseDayHours(),
      photos: _getPhotos(),
      onboarded: EditMeta(date: onboardedAt, by: onboardedByName ?? ''),
      lastEdited: EditMeta(date: updatedAt, by: lastEditedByName ?? ''),
      services: [],
      settlement: const Settlement(
        lastSettled: '',
        lifetimePaid: 0,
        pending: [],
        history: [],
      ),
      weekly: _parseWeeklyDays(),
      slotCapacityEnabled: operationalConfig.useSlotLevelCapacity,
      slotCap: operationalConfig.dailyBookingCap,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Cover first, then the extras. BunnyCDN hands these back as a bare
  /// `host/path` with no scheme, which `NetworkImage` refuses to fetch — so
  /// every one goes through [resolveMediaUrl] before it reaches the widget.
  List<String> _getPhotos() {
    return [
      coverImageUrl,
      normalImage1Url,
      normalImage2Url,
      normalImage3Url,
      normalImage4Url,
    ].map(resolveMediaUrl).whereType<String>().toList();
  }

  List<DayHours> _parseDayHours() {
    return operatingHours
        .map((h) => DayHours(
              day: h.label,
              open: h.openingTime ?? '—',
              close: h.closingTime ?? '—',
              closed: !h.isOpen,
            ))
        .toList();
  }

  List<WeeklyDay> _parseWeeklyDays() {
    return operatingHours
        .map((h) => WeeklyDay(
              day: h.label,
              weekday: h.weekday,
              closed: !h.isOpen,
              open: h.isOpen ? _parseHour(h.openingTime) : 0,
              close: h.isOpen ? _parseHour(h.closingTime) : 0,
            ))
        .toList();
  }

  static int _parseHour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 9;
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
        .firstMatch(timeStr);
    if (match == null) return 9;
    int h = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toUpperCase() == 'PM') h += 12;
    return h;
  }

  /// The API speaks in slugs (`suv`) while the vehicle-type chips are labelled
  /// in display case (`SUV`), so a slug never matched and every supported type
  /// rendered as unselected. Prefer the label the API already ships.
  static String _displayVehicleType(VehicleTypeModel v) =>
      v.label.isNotEmpty ? v.label : v.value;

  static Commission _parseCommission(CommissionDetailModel? c) {
    if (c == null) {
      return const Commission(mode: CommissionMode.flat, flat: 0);
    }

    if (c.type == 'percentage') {
      return Commission(
        mode: CommissionMode.percentage,
        pct: _asInt(c.percentage),
      );
    } else if (c.type == 'percent_floor') {
      return Commission(
        mode: CommissionMode.floor,
        pct: _asInt(c.percentage),
        floor: _asInt(c.floor),
      );
    } else {
      return Commission(
        mode: CommissionMode.flat,
        flat: _asInt(c.amount),
      );
    }
  }

  /// The commission numbers arrive as decimals (`15.0`) — parsing those as an
  /// int fails outright, which is how a 15% shop ended up showing 0%.
  static int _asInt(Object? value) => switch (value) {
        final num n => n.round(),
        final String s => (double.tryParse(s) ?? 0).round(),
        _ => 0,
      };

  static BankDetails _parseBank(BankDetailModel? b) {
    return BankDetails(
      accName: b?.accountName ?? '',
      accNo: b?.accountNumber ?? '',
      ifsc: b?.ifsc ?? '',
      upi: b?.upiId ?? '',
      gstin: b?.gstin ?? '',
      pan: b?.pan ?? '',
    );
  }
}

class CapacityDetailModel {
  final int used;
  final int total;

  CapacityDetailModel({required this.used, required this.total});

  factory CapacityDetailModel.fromJson(Map<String, dynamic> json) {
    return CapacityDetailModel(
      used: json['used'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

class OperatingHourModel {
  final int weekday;
  final String label;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;
  final String display;

  OperatingHourModel({
    required this.weekday,
    required this.label,
    required this.isOpen,
    this.openingTime,
    this.closingTime,
    required this.display,
  });

  factory OperatingHourModel.fromJson(Map<String, dynamic> json) {
    return OperatingHourModel(
      weekday: json['weekday'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      display: json['display'] as String? ?? 'Off day',
    );
  }
}

class HolidayModel {
  final String date;
  final String label;

  HolidayModel({required this.date, required this.label});

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

class OperationalConfigModel {
  final int dailyBookingCap;
  final List<VehicleTypeModel> vehicleTypes;
  final bool isActive;
  final bool useSlotLevelCapacity;

  OperationalConfigModel({
    required this.dailyBookingCap,
    required this.vehicleTypes,
    required this.isActive,
    required this.useSlotLevelCapacity,
  });

  factory OperationalConfigModel.fromJson(Map<String, dynamic> json) {
    return OperationalConfigModel(
      dailyBookingCap: json['daily_booking_cap'] as int? ?? 0,
      vehicleTypes: ((json['vehicle_types'] as List<dynamic>?) ?? [])
          .map((v) => VehicleTypeModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      isActive: json['is_active'] as bool? ?? true,
      useSlotLevelCapacity: json['use_slot_level_capacity'] as bool? ?? false,
    );
  }
}

class VehicleTypeModel {
  final String value;
  final String label;
  final bool supported;

  VehicleTypeModel({
    required this.value,
    required this.label,
    required this.supported,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
      supported: json['supported'] as bool? ?? false,
    );
  }
}

class SettlementModel {
  final CommissionDetailModel commission;
  final BankDetailModel? bank;

  SettlementModel({required this.commission, this.bank});

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      commission: CommissionDetailModel.fromJson(
        json['commission'] as Map<String, dynamic>? ?? {},
      ),
      bank: json['bank'] != null
          ? BankDetailModel.fromJson(json['bank'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CommissionDetailModel {
  final String type; // 'flat', 'percentage', 'percent_floor'
  final double? percentage;
  final String? amount;
  final double? floor;
  final String label;

  CommissionDetailModel({
    required this.type,
    this.percentage,
    this.amount,
    this.floor,
    required this.label,
  });

  factory CommissionDetailModel.fromJson(Map<String, dynamic> json) {
    return CommissionDetailModel(
      type: json['type'] as String? ?? 'flat',
      percentage: (json['percentage'] as num?)?.toDouble(),
      amount: json['amount'] != null ? (json['amount'] as num).toInt().toString() : null,
      floor: (json['floor'] as num?)?.toDouble(),
      label: json['label'] as String? ?? '',
    );
  }
}

class BankDetailModel {
  final String accountName;
  final String accountNumber;
  final String ifsc;
  final String upiId;
  final String? gstin;
  final String? pan;

  BankDetailModel({
    required this.accountName,
    required this.accountNumber,
    required this.ifsc,
    required this.upiId,
    this.gstin,
    this.pan,
  });

  factory BankDetailModel.fromJson(Map<String, dynamic> json) {
    return BankDetailModel(
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      ifsc: json['ifsc'] as String? ?? '',
      upiId: json['upi_id'] as String? ?? '',
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
    );
  }
}

/// Shop edit request for PATCH /api/shop/v1/shops/{id}/
///
/// Every field is optional and `null` ones are left out of the body: a PATCH
/// must only carry what the admin actually changed, or unedited columns (city
/// and state, which this form has no inputs for) would be blanked out.
class ShopUpdateRequest {
  const ShopUpdateRequest({
    this.name,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.phone,
    this.ownerName,
    this.ownerPhone,
    this.latitude,
    this.longitude,
    this.dailyBookingCap,
    this.supportedVehicleTypes,
    this.commissionType,
    this.commissionPercentage,
    this.commissionAmount,
    this.commissionFloor,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.gstin,
    this.pan,
    this.useSlotLevelCapacity,
  });

  final String? name;
  final String? address;
  final String? pincode;
  final String? city;
  final String? state;
  final String? phone;
  final String? ownerName;
  final String? ownerPhone;
  final double? latitude;
  final double? longitude;
  final int? dailyBookingCap;
  final List<String>? supportedVehicleTypes;
  final String? commissionType;
  final String? commissionPercentage;
  final String? commissionAmount;
  final String? commissionFloor;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;
  final String? gstin;
  final String? pan;
  final bool? useSlotLevelCapacity;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (pincode != null) 'pincode': pincode,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (phone != null) 'phone': phone,
        if (ownerName != null) 'owner_name': ownerName,
        if (ownerPhone != null) 'owner_phone': ownerPhone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (dailyBookingCap != null) 'daily_booking_cap': dailyBookingCap,
        if (supportedVehicleTypes != null)
          'supported_vehicle_types': supportedVehicleTypes,
        if (commissionType != null) 'commission_type': commissionType,
        if (commissionPercentage != null)
          'commission_percentage': commissionPercentage,
        if (commissionAmount != null) 'commission_amount': commissionAmount,
        if (commissionFloor != null) 'commission_floor': commissionFloor,
        if (bankAccountName != null) 'bank_account_name': bankAccountName,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankIfsc != null) 'bank_ifsc': bankIfsc,
        if (upiId != null) 'upi_id': upiId,
        if (gstin != null) 'gstin': gstin,
        if (pan != null) 'pan': pan,
        if (useSlotLevelCapacity != null)
          'use_slot_level_capacity': useSlotLevelCapacity,
      };
}

/// Shop creation request for POST /api/shop/v1/shops/
class ShopCreateRequest {
  final String name;
  final String address;
  final String pincode;
  final String city;
  final String state;
  final String phone;
  final String ownerName;
  final String ownerPhone;
  final int? dailyBookingCap;
  final List<String> supportedVehicleTypes;
  final String commissionType;
  final String? commissionPercentage;
  final String? commissionAmount;
  final String? commissionFloor;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;
  final String? gstin;
  final String? pan;

  /// Coordinates of the point picked on the map. Optional — `location` is
  /// nullable server-side, but a shop is excluded from distance-sorted /
  /// nearby results until both are set.
  final double? latitude;
  final double? longitude;

  ShopCreateRequest({
    required this.name,
    required this.address,
    required this.pincode,
    required this.city,
    required this.state,
    required this.phone,
    required this.ownerName,
    required this.ownerPhone,
    this.latitude,
    this.longitude,
    this.dailyBookingCap,
    this.supportedVehicleTypes = const [],
    this.commissionType = 'flat',
    this.commissionPercentage,
    this.commissionAmount,
    this.commissionFloor,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.gstin,
    this.pan,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'pincode': pincode,
        'city': city,
        'state': state,
        'phone': phone,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'daily_booking_cap': dailyBookingCap,
        'supported_vehicle_types': supportedVehicleTypes,
        'commission_type': commissionType,
        if (commissionPercentage != null) 'commission_percentage': commissionPercentage,
        if (commissionAmount != null) 'commission_amount': commissionAmount,
        if (commissionFloor != null) 'commission_floor': commissionFloor,
        if (bankAccountName != null) 'bank_account_name': bankAccountName,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankIfsc != null) 'bank_ifsc': bankIfsc,
        if (upiId != null) 'upi_id': upiId,
        if (gstin != null) 'gstin': gstin,
        if (pan != null) 'pan': pan,
      };
}
