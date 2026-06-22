import 'package:flutter/foundation.dart';

/// Refund summary response from GET /api/booking/v1/admin/refunds/carwash/{booking_id}/
class RefundSummaryResponse {
  final int amountPaid;
  final int totalRefunded;
  final int remaining;
  final List<RefundHistoryItem> refunds;

  RefundSummaryResponse({
    required this.amountPaid,
    required this.totalRefunded,
    required this.remaining,
    required this.refunds,
  });

  factory RefundSummaryResponse.fromJson(Map<String, dynamic> json) {
    try {
      List<RefundHistoryItem> refundsList = [];
      try {
        refundsList = (json['refunds'] as List?)
                ?.map((e) => RefundHistoryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } catch (e) {
        debugPrint('Error parsing refunds list: $e');
      }

      return RefundSummaryResponse(
        amountPaid: _toInt(json['amount_paid']),
        totalRefunded: _toInt(json['total_refunded']),
        remaining: _toInt(json['remaining']),
        refunds: refundsList,
      );
    } catch (e) {
      debugPrint('Error parsing RefundSummaryResponse: $e');
      return RefundSummaryResponse(
        amountPaid: 0,
        totalRefunded: 0,
        remaining: 0,
        refunds: [],
      );
    }
  }
}

/// Single refund history item
class RefundHistoryItem {
  final int id;
  final int amount;
  final String reason;
  final String? comment;
  final String createdAt;

  RefundHistoryItem({
    required this.id,
    required this.amount,
    required this.reason,
    this.comment,
    required this.createdAt,
  });

  factory RefundHistoryItem.fromJson(Map<String, dynamic> json) {
    return RefundHistoryItem(
      id: _toInt(json['id']),
      amount: _toInt(json['amount']),
      reason: _toString(json['reason']) ?? 'Unknown',
      comment: _toString(json['comment']),
      createdAt: _toString(json['created_at']) ?? '',
    );
  }
}

/// Refund response from POST /api/booking/v1/admin/refunds/carwash/{booking_id}/
class RefundResponse {
  final int id;
  final int amount;
  final String reason;
  final String? comment;
  final String createdAt;
  final int amountPaid;
  final int totalRefunded;
  final int remaining;

  RefundResponse({
    required this.id,
    required this.amount,
    required this.reason,
    this.comment,
    required this.createdAt,
    required this.amountPaid,
    required this.totalRefunded,
    required this.remaining,
  });

  factory RefundResponse.fromJson(Map<String, dynamic> json) {
    try {
      return RefundResponse(
        id: _toInt(json['id']),
        amount: _toInt(json['amount']),
        reason: _toString(json['reason']) ?? 'Unknown',
        comment: _toString(json['comment']),
        createdAt: _toString(json['created_at']) ?? '',
        amountPaid: _toInt(json['amount_paid']),
        totalRefunded: _toInt(json['total_refunded']),
        remaining: _toInt(json['remaining']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundResponse: $e');
      rethrow;
    }
  }
}

// Helper functions
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (_) {
      return 0;
    }
  }
  return 0;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}
