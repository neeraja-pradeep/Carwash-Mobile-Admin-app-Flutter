import 'package:flutter/foundation.dart';

import '../../domain/entities/coupon.dart';

/// Coupon list response from GET /api/booking/v1/coupons/
/// (standard DRF paginated envelope).
class CouponListResponse {
  final List<CouponModel> results;
  final int count;
  final String? next;
  final String? previous;

  CouponListResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  factory CouponListResponse.fromJson(Map<String, dynamic> json) {
    // Parse each coupon independently so one malformed entry can't collapse the
    // whole page to empty — skip (and log) the bad item, keep the good ones.
    final rawResults = (json['results'] as List?) ?? const [];
    final resultsList = <CouponModel>[];
    for (final e in rawResults) {
      try {
        resultsList.add(CouponModel.fromJson(e as Map<String, dynamic>));
      } catch (err) {
        debugPrint('Skipping malformed coupon in list: $err — raw: $e');
      }
    }

    return CouponListResponse(
      results: resultsList,
      count: _toInt(json['count']),
      next: _toString(json['next']),
      previous: _toString(json['previous']),
    );
  }
}

/// A single coupon from the read serializer (`CouponSerializer`).
class CouponModel {
  final String id;
  final String name;
  final String description;
  final String discountType;
  final double? discountPercentage;
  final double? flatAmount;
  final double? maxDiscount;
  final double? minOrder;
  final String discountLabel;
  final int limit;
  final int? perUserLimit;
  final int usage;
  final int usageRemaining;
  final bool appliesToAllShops;
  final List<int> shopIds;
  final String? startDate;
  final String? endDate;
  final bool status;
  final bool isActive;
  final String lifecycleStatus;
  final String? createdAt;
  final String? updatedAt;

  CouponModel({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    this.discountPercentage,
    this.flatAmount,
    this.maxDiscount,
    this.minOrder,
    required this.discountLabel,
    required this.limit,
    this.perUserLimit,
    required this.usage,
    required this.usageRemaining,
    required this.appliesToAllShops,
    required this.shopIds,
    this.startDate,
    this.endDate,
    required this.status,
    required this.isActive,
    required this.lifecycleStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    try {
      return CouponModel(
        id: _toString(json['id']) ?? '',
        name: _toString(json['name']) ?? '',
        description: _toString(json['description']) ?? '',
        discountType: _toString(json['discount_type']) ?? 'percentage',
        discountPercentage: _toDouble(json['discount_percentage']),
        flatAmount: _toDouble(json['flat_amount']),
        maxDiscount: _toDouble(json['max_discount']),
        minOrder: _toDouble(json['min_order']),
        discountLabel: _toString(json['discount_label']) ?? '',
        limit: _toInt(json['limit']),
        perUserLimit: _toIntOrNull(json['per_user_limit']),
        usage: _toInt(json['usage']),
        usageRemaining: _toInt(json['usage_remaining']),
        appliesToAllShops: _toBool(json['applies_to_all_shops']),
        shopIds: _toIntList(json['shop_ids']),
        startDate: _toString(json['start_date']),
        endDate: _toString(json['end_date']),
        status: _toBool(json['status']),
        isActive: _toBool(json['is_active']),
        lifecycleStatus: _toString(json['lifecycle_status']) ?? 'active',
        createdAt: _toString(json['created_at']),
        updatedAt: _toString(json['updated_at']),
      );
    } catch (e) {
      debugPrint('Error parsing CouponModel: $e');
      rethrow;
    }
  }

  Coupon toEntity() {
    return Coupon(
      id: id,
      name: name,
      description: description,
      discountType: discountType,
      discountPercentage: discountPercentage,
      flatAmount: flatAmount,
      maxDiscount: maxDiscount,
      minOrder: minOrder,
      discountLabel: discountLabel,
      limit: limit,
      perUserLimit: perUserLimit,
      usage: usage,
      usageRemaining: usageRemaining,
      appliesToAllShops: appliesToAllShops,
      shopIds: shopIds,
      startDate: _parseDate(startDate),
      endDate: _parseDate(endDate),
      statusActive: status,
      isActive: isActive,
      lifecycleStatus: lifecycleStatus,
    );
  }
}

/// Builds the create/update (`CouponCreateUpdateSerializer`) payload.
///
/// All fields optional so it doubles as the PATCH builder — only pass the
/// fields that should be sent. Date values must already be ISO-8601 strings.
Map<String, dynamic> buildCouponPayload({
  String? name,
  String? description,
  String? discountType,
  num? discountPercentage,
  num? flatAmount,
  num? maxDiscount,
  num? minOrder,
  bool? appliesToAllShops,
  List<int>? shopIds,
  int? limit,
  int? perUserLimit,
  String? startDate,
  String? endDate,
  bool? status,
}) {
  return {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (discountType != null) 'discount_type': discountType,
    if (discountPercentage != null) 'discount_percentage': discountPercentage,
    if (flatAmount != null) 'flat_amount': flatAmount,
    if (maxDiscount != null) 'max_discount': maxDiscount,
    if (minOrder != null) 'min_order': minOrder,
    if (appliesToAllShops != null) 'applies_to_all_shops': appliesToAllShops,
    if (shopIds != null) 'shop_ids': shopIds,
    if (limit != null) 'limit': limit,
    if (perUserLimit != null) 'per_user_limit': perUserLimit,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
    if (status != null) 'status': status,
  };
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
}

List<int> _toIntList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => _toIntOrNull(e))
        .whereType<int>()
        .toList();
  }
  return const [];
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}
