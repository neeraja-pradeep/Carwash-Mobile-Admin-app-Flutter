import 'package:flutter/foundation.dart';

/// An available booking slot returned by `GET /api/booking/v1/slots-available/`.
/// Resolves a typed/selected time into a `Slot` id for `start_slot`.
class SlotOption {
  final int id;
  final String time; // raw "HH:MM[:SS]" from the API
  final String label; // human label, e.g. "10:30 AM"
  final bool available;

  SlotOption({
    required this.id,
    required this.time,
    required this.label,
    required this.available,
  });

  factory SlotOption.fromJson(Map<String, dynamic> json) {
    final rawTime = _toString(json['time']) ??
        _toString(json['start_time']) ??
        _toString(json['slot_time']) ??
        '';
    final label = _toString(json['label']) ??
        _toString(json['display']) ??
        _formatTime(rawTime);
    // Treat missing `available` as available (some payloads omit it).
    final avail = json['available'];
    return SlotOption(
      id: _toInt(json['id']),
      time: rawTime,
      label: label,
      available: avail is bool ? avail : true,
    );
  }
}

/// Parses the slots-available response into a list of [SlotOption].
List<SlotOption> parseSlotOptions(dynamic data) {
  try {
    List? raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      raw = (data['slots'] as List?) ??
          (data['results'] as List?) ??
          (data['available'] as List?);
    }
    return raw
            ?.whereType<Map<String, dynamic>>()
            .map(SlotOption.fromJson)
            .toList() ??
        [];
  } catch (e) {
    debugPrint('Error parsing slot options: $e');
    return [];
  }
}

/// Coupon validation preview from `POST /api/booking/v1/validate-coupon/`.
class CouponPreview {
  final bool valid;
  final String? code;
  final int discount;
  final int originalAmount;
  final int finalAmount;
  final String? message;

  CouponPreview({
    required this.valid,
    this.code,
    required this.discount,
    required this.originalAmount,
    required this.finalAmount,
    this.message,
  });

  factory CouponPreview.fromJson(Map<String, dynamic> json) {
    try {
      final discount = _toInt(json['discount'] ??
          json['discount_amount'] ??
          json['discount_value']);
      final original =
          _toInt(json['original_amount'] ?? json['order_amount'] ?? json['amount']);
      final finalAmt = json.containsKey('final_amount')
          ? _toInt(json['final_amount'])
          : json.containsKey('payable_amount')
              ? _toInt(json['payable_amount'])
              : (original - discount);
      // `valid` defaults to true when a discount resolves and no explicit flag.
      final validRaw = json['valid'] ?? json['is_valid'];
      return CouponPreview(
        valid: validRaw is bool ? validRaw : true,
        code: _toString(json['code'] ?? json['coupon_code']),
        discount: discount,
        originalAmount: original,
        finalAmount: finalAmt,
        message: _toString(json['message'] ?? json['detail']),
      );
    } catch (e) {
      debugPrint('Error parsing CouponPreview: $e');
      rethrow;
    }
  }
}

/// A vehicle created via `POST /api/accounts/v1/cars/`.
class CreatedVehicle {
  final int id;
  final String? brandModel;
  final String? registration;
  final String? carType;

  CreatedVehicle({
    required this.id,
    this.brandModel,
    this.registration,
    this.carType,
  });

  factory CreatedVehicle.fromJson(Map<String, dynamic> json) {
    try {
      return CreatedVehicle(
        id: _toInt(json['id']),
        brandModel: _toString(json['brand_model']),
        registration: _toString(json['registration']),
        carType: _toString(json['car_type']),
      );
    } catch (e) {
      debugPrint('Error parsing CreatedVehicle: $e');
      rethrow;
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

String _formatTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';
  try {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  } catch (_) {
    return timeStr;
  }
}
