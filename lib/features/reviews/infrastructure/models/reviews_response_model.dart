import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/review.dart';

/// Reviews list response from GET /api/shop/v1/admin/reviews/
///
/// Custom paginated envelope: `{count, page, page_size, next, previous, results}`.
class ReviewsPageResponse {
  final List<ReviewModel> results;
  final int count;
  final int page;
  final int pageSize;
  final String? next;
  final String? previous;

  ReviewsPageResponse({
    required this.results,
    required this.count,
    required this.page,
    required this.pageSize,
    this.next,
    this.previous,
  });

  factory ReviewsPageResponse.fromJson(Map<String, dynamic> json) {
    try {
      final resultsList = (json['results'] as List?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return ReviewsPageResponse(
        results: resultsList,
        count: _toInt(json['count']),
        page: _toInt(json['page']),
        pageSize: _toInt(json['page_size']),
        next: _toString(json['next']),
        previous: _toString(json['previous']),
      );
    } catch (e) {
      debugPrint('Error parsing ReviewsPageResponse: $e');
      return ReviewsPageResponse(
        results: [],
        count: 0,
        page: 1,
        pageSize: 0,
      );
    }
  }
}

/// A review card from the list response `results[]`.
class ReviewModel {
  final int id;
  final double rating;
  final String? comment;
  final bool hasComment;
  final String? customerName;
  final String? shopName;
  final int? shopId;
  final String? createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.hasComment,
    this.customerName,
    this.shopName,
    this.shopId,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    try {
      return ReviewModel(
        id: _toInt(json['id']),
        rating: _toDouble(json['rating']),
        comment: _toString(json['comment']),
        hasComment: _toBool(json['has_comment']),
        customerName: _toString(json['customer_name']),
        shopName: _toString(json['shop_name']),
        shopId: json['shop_id'] == null ? null : _toInt(json['shop_id']),
        createdAt: _toString(json['created_at']),
      );
    } catch (e) {
      debugPrint('Error parsing ReviewModel: $e');
      rethrow;
    }
  }

  Review toEntity() {
    final dt = _parseDate(createdAt);
    return Review(
      id: id.toString(),
      rating: rating.round(),
      customer: customerName ?? 'Unknown',
      phone: '',
      shop: shopName ?? '',
      date: _formatDate(dt),
      time: _formatTime(dt),
      bookingId: '',
      drivers: const [],
      text: comment ?? '',
      shopId: shopId,
    );
  }
}

/// Review detail response from GET /api/shop/v1/admin/reviews/{review_id}/
class ReviewDetailModel {
  final int id;
  final double rating;
  final String? comment;
  final List<String> tags;
  final String? customerName;
  final String? customerPhone;
  final String? shopName;
  final int? shopId;
  final String? bookingReference;
  final int? bookingId;
  final String? handledBy;
  final bool isFlagged;
  final String? createdAt;

  ReviewDetailModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.tags,
    this.customerName,
    this.customerPhone,
    this.shopName,
    this.shopId,
    this.bookingReference,
    this.bookingId,
    this.handledBy,
    required this.isFlagged,
    this.createdAt,
  });

  factory ReviewDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      final tagsList = (json['tags'] as List?)
              ?.map((e) => _toString(e) ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];

      return ReviewDetailModel(
        id: _toInt(json['id']),
        rating: _toDouble(json['rating']),
        comment: _toString(json['comment']),
        tags: tagsList,
        customerName: _toString(json['customer_name']),
        customerPhone: _toString(json['customer_phone']),
        shopName: _toString(json['shop_name']),
        shopId: json['shop_id'] == null ? null : _toInt(json['shop_id']),
        bookingReference: _toString(json['booking_reference']),
        bookingId: json['booking_id'] == null ? null : _toInt(json['booking_id']),
        handledBy: _toString(json['handled_by']),
        isFlagged: _toBool(json['is_flagged']),
        createdAt: _toString(json['created_at']),
      );
    } catch (e) {
      debugPrint('Error parsing ReviewDetailModel: $e');
      rethrow;
    }
  }

  Review toEntity() {
    final dt = _parseDate(createdAt);
    return Review(
      id: id.toString(),
      rating: rating.round(),
      customer: customerName ?? 'Unknown',
      phone: customerPhone ?? '',
      shop: shopName ?? '',
      date: _formatDate(dt),
      time: _formatTime(dt),
      bookingId: bookingReference ?? '',
      drivers: handledBy == null || handledBy!.isEmpty ? const [] : [handledBy!],
      text: comment ?? '',
      tags: tags,
      bookingIntId: bookingId,
      isFlagged: isFlagged,
      customerPhone: customerPhone,
      handledBy: handledBy,
      shopId: shopId,
    );
  }
}

// Helper functions

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String _formatDate(DateTime? dt) =>
    dt == null ? '' : DateFormat('d MMM').format(dt);

String _formatTime(DateTime? dt) =>
    dt == null ? '' : DateFormat('h:mm a').format(dt);

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}
