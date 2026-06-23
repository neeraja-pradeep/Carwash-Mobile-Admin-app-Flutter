import 'package:flutter/foundation.dart';
import '../../domain/entities/refund.dart';

/// Refund list response from GET /api/booking/v1/admin/refunds/
class RefundListResponse {
  final List<RefundModel> results;
  final int count;
  final String? next;
  final String? previous;

  RefundListResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  factory RefundListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final resultsList = (json['results'] as List?)
              ?.map((e) => RefundModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return RefundListResponse(
        results: resultsList,
        count: _toInt(json['count']),
        next: _toString(json['next']),
        previous: _toString(json['previous']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundListResponse: $e');
      return RefundListResponse(
        results: [],
        count: 0,
      );
    }
  }
}

/// Refund detail response from GET /api/booking/v1/admin/refunds/{id}/
class RefundDetailResponse {
  final String id;
  final int amount;
  final String status;
  final String bookingId;
  final RefundCustomerModel customer;
  final String tier;
  final String reason;
  final String? comment;
  final String createdAt;
  final String? approvedAt;
  final String? paidAt;
  final String? razorpayRefundId;
  final String? utr;

  RefundDetailResponse({
    required this.id,
    required this.amount,
    required this.status,
    required this.bookingId,
    required this.customer,
    required this.tier,
    required this.reason,
    this.comment,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
    this.razorpayRefundId,
    this.utr,
  });

  factory RefundDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      return RefundDetailResponse(
        id: _toString(json['id']) ?? '',
        amount: _toInt(json['amount']),
        status: _toString(json['status']) ?? 'requested',
        bookingId: _toString(json['booking_id']) ?? '',
        customer: RefundCustomerModel.fromJson(
          json['customer'] as Map<String, dynamic>? ?? {},
        ),
        tier: _toString(json['tier']) ?? '100%',
        reason: _toString(json['reason']) ?? 'other',
        comment: _toString(json['comment']),
        createdAt: _toString(json['created_at']) ?? '',
        approvedAt: _toString(json['approved_at']),
        paidAt: _toString(json['paid_at']),
        razorpayRefundId: _toString(json['razorpay_refund_id']),
        utr: _toString(json['utr']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundDetailResponse: $e');
      rethrow;
    }
  }

  Refund toEntity() {
    return Refund(
      id: id,
      amount: amount,
      status: status,
      bookingId: bookingId,
      customer: RefundCustomer(
        name: customer.name,
        phone: customer.phone,
      ),
      tier: tier,
      reason: reason,
      notes: comment ?? '',
      createdAt: createdAt,
      approvedAt: approvedAt,
      paidAt: paidAt,
      utr: utr ?? '',
      proof: utr?.isNotEmpty ?? false,
    );
  }
}

/// Refund model from list response
class RefundModel {
  final String id;
  final int amount;
  final String status;
  final String bookingId;
  final RefundCustomerModel customer;
  final String reason;
  final String? comment;
  final String createdAt;

  RefundModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.bookingId,
    required this.customer,
    required this.reason,
    this.comment,
    required this.createdAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    try {
      return RefundModel(
        id: _toString(json['id']) ?? '',
        amount: _toInt(json['amount']),
        status: _toString(json['status']) ?? 'requested',
        bookingId: _toString(json['booking_id']) ?? '',
        customer: RefundCustomerModel.fromJson(
          json['customer'] as Map<String, dynamic>? ?? {},
        ),
        reason: _toString(json['reason']) ?? 'other',
        comment: _toString(json['comment']),
        createdAt: _toString(json['created_at']) ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing RefundModel: $e');
      rethrow;
    }
  }

  Refund toEntity() {
    return Refund(
      id: id,
      amount: amount,
      status: status,
      bookingId: bookingId,
      customer: RefundCustomer(
        name: customer.name,
        phone: customer.phone,
      ),
      tier: 'N/A',
      reason: reason,
      notes: comment ?? '',
      createdAt: createdAt,
      utr: '',
      proof: false,
    );
  }
}

/// Customer model within refund response
class RefundCustomerModel {
  final String name;
  final String phone;

  RefundCustomerModel({required this.name, required this.phone});

  factory RefundCustomerModel.fromJson(Map<String, dynamic> json) {
    return RefundCustomerModel(
      name: _toString(json['name']) ?? 'Unknown',
      phone: _toString(json['phone']) ?? '',
    );
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
