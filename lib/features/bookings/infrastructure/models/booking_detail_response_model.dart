import 'package:flutter/foundation.dart';

/// Full booking detail response from GET /api/booking/v1/bookings/{id}/
class BookingDetailResponse {
  final int id;
  final String reference;
  final String status;
  final String? washingStatus;
  final String? amount;
  final bool? isPaid;
  final String? paymentStatus;
  final String? customerName;
  final String? customerPhone;
  final String? vehicleLabel;
  final String? car;
  final String? startSlotTime;
  final String? appointmentDate;
  final AddressDetail? addressDetail;
  final ShopDetail? shop;
  final String? dropAddress;
  final List<ServiceDetail>? services;
  final DriverDetail? driver;
  final List<TimelineEvent>? timeline;
  final DamageReport? damage;

  BookingDetailResponse({
    required this.id,
    required this.reference,
    required this.status,
    this.washingStatus,
    this.amount,
    this.isPaid,
    this.paymentStatus,
    this.customerName,
    this.customerPhone,
    this.vehicleLabel,
    this.car,
    this.startSlotTime,
    this.appointmentDate,
    this.addressDetail,
    this.shop,
    this.dropAddress,
    this.services,
    this.driver,
    this.timeline,
    this.damage,
  });

  factory BookingDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse services
      List<ServiceDetail>? servicesList;
      try {
        servicesList = (json['services'] as List?)
            ?.map((e) => ServiceDetail.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing services: $e');
        servicesList = null;
      }

      // Safely parse timeline
      List<TimelineEvent>? timelineList;
      try {
        timelineList = (json['timeline'] as List?)
            ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing timeline: $e');
        timelineList = null;
      }

      return BookingDetailResponse(
        id: _toInt(json['id']),
        reference: _toStringOrEmpty(json['reference']),
        status: _toStringOrEmpty(json['status']),
        washingStatus: _toString(json['washing_status']),
        amount: _parseAmount(json['amount']),
        isPaid: json['is_paid'] as bool?,
        paymentStatus: _toString(json['payment_status']),
        customerName: _toString(json['customer_name']),
        customerPhone: _toString(json['customer_phone']),
        vehicleLabel: _toString(json['vehicle_label']),
        car: _toString(json['car']),
        startSlotTime: _toString(json['start_slot_time']),
        appointmentDate: _toString(json['appointment_date']),
        addressDetail: json['address_detail'] != null
            ? AddressDetail.fromJson(json['address_detail'] as Map<String, dynamic>)
            : null,
        shop: json['shop'] != null
            ? ShopDetail.fromJson(json['shop'] as Map<String, dynamic>)
            : null,
        dropAddress: _toString(json['drop_address']),
        services: servicesList,
        driver: json['driver'] != null
            ? DriverDetail.fromJson(json['driver'] as Map<String, dynamic>)
            : null,
        timeline: timelineList,
        damage: json['damage'] != null
            ? DamageReport.fromJson(json['damage'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw Exception('Failed to parse BookingDetailResponse: $e');
    }
  }

  static String? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _toStringOrEmpty(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return '';
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return null;
  }
}

class AddressDetail {
  final double? latitude;
  final double? longitude;
  final String? address;

  AddressDetail({this.latitude, this.longitude, this.address});

  factory AddressDetail.fromJson(Map<String, dynamic> json) {
    return AddressDetail(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      address: json['address'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ShopDetail {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  ShopDetail({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    // Handle nested user object
    final user = json['user'] as Map<String, dynamic>?;
    return ShopDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? (json['formatted_address'] as String?),
      phone: json['phone'] as String? ?? (user?['phone'] as String?),
      latitude: _toDouble(json['latitude'] ?? user?['latitude']),
      longitude: _toDouble(json['longitude'] ?? user?['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ServiceDetail {
  final String name;
  final int? estimatedMinutes;
  final String? amount;

  ServiceDetail({required this.name, this.estimatedMinutes, this.amount});

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    return ServiceDetail(
      name: json['service_name'] as String? ?? '',
      estimatedMinutes: json['estimated_minutes'] as int?,
      amount: json['amount']?.toString(),
    );
  }
}

class DriverDetail {
  final int id;
  final String name;
  final String? title;
  final String? phone;
  final String? maskedPhone;
  final double? rating;

  DriverDetail({
    required this.id,
    required this.name,
    this.title,
    this.phone,
    this.maskedPhone,
    this.rating,
  });

  factory DriverDetail.fromJson(Map<String, dynamic> json) {
    return DriverDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      title: json['title'] as String?,
      phone: json['phone'] as String?,
      maskedPhone: json['masked_phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class TimelineEvent {
  final String? washingStatus;
  final String? actor;
  final String? createdAt;

  TimelineEvent({this.washingStatus, this.actor, this.createdAt});

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      washingStatus: json['washing_status'] as String?,
      actor: json['actor'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class DamageReport {
  final DamageStage? pickup;
  final DamageStage? drop;

  DamageReport({this.pickup, this.drop});

  factory DamageReport.fromJson(Map<String, dynamic> json) {
    return DamageReport(
      pickup: json['pickup'] != null
          ? DamageStage.fromJson(json['pickup'] as Map<String, dynamic>)
          : null,
      drop: json['drop'] != null
          ? DamageStage.fromJson(json['drop'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DamageStage {
  final String stage;
  final bool? checked;
  final String? issuesFound;
  final List<String>? damageTypes;
  final List<String>? panels;
  final String? notes;
  final String? voiceNoteUrl;

  DamageStage({
    required this.stage,
    this.checked,
    this.issuesFound,
    this.damageTypes,
    this.panels,
    this.notes,
    this.voiceNoteUrl,
  });

  factory DamageStage.fromJson(Map<String, dynamic> json) {
    return DamageStage(
      stage: json['stage'] as String? ?? '',
      checked: json['checked'] as bool?,
      issuesFound: json['issues_found'] as String?,
      damageTypes:
          (json['damage_types'] as List?)?.cast<String>(),
      panels: (json['panels'] as List?)?.cast<String>(),
      notes: json['notes'] as String?,
      voiceNoteUrl: json['voice_note_url'] as String?,
    );
  }
}

/// Assignable drivers response
class AssignableDriversResponse {
  final int count;
  final List<AssignableDriver> items;

  AssignableDriversResponse({required this.count, required this.items});

  factory AssignableDriversResponse.fromJson(Map<String, dynamic> json) {
    return AssignableDriversResponse(
      count: json['count'] as int? ?? 0,
      items: (json['items'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => AssignableDriver.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AssignableDriver {
  final int id;
  final String name;
  final String? title;
  final String? phone;
  final String? maskedPhone;
  final double? rating;
  final bool? available;

  AssignableDriver({
    required this.id,
    required this.name,
    this.title,
    this.phone,
    this.maskedPhone,
    this.rating,
    this.available,
  });

  factory AssignableDriver.fromJson(Map<String, dynamic> json) {
    return AssignableDriver(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      title: json['title'] as String?,
      phone: json['phone'] as String?,
      maskedPhone: json['masked_phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      available: json['available'] as bool?,
    );
  }
}
