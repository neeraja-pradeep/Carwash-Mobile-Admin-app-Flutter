import 'package:flutter/foundation.dart';
import '../../domain/entities/refund.dart';

/// Refund list response from GET /api/booking/v1/admin/refunds/
///
/// Custom paginated envelope: {count, page, page_size, next, previous, results}.
class RefundListResponse {
  final List<RefundModel> results;
  final int count;
  final int page;
  final int pageSize;
  final String? next;
  final String? previous;

  RefundListResponse({
    required this.results,
    required this.count,
    this.page = 1,
    this.pageSize = 20,
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
        page: _toInt(json['page']),
        pageSize: _toInt(json['page_size']),
        next: _toString(json['next']),
        previous: _toString(json['previous']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundListResponse: $e');
      return RefundListResponse(results: [], count: 0);
    }
  }
}

/// Refund detail response from
/// GET /api/booking/v1/admin/refunds/detail/{id_or_reference}/
/// (also the shape returned under `refund` by approve/mark-paid/create/decline).
class RefundDetailResponse {
  final String id;
  final String? reference;
  final String? bookingType;
  final String bookingId;
  final String? bookingReference;
  final String customerName;
  final String customerPhone;
  final int amount;
  final double? percent;
  final String? tierLabel;
  final String reason;
  final String? reasonLabel;
  final String? reasonSubtitle;
  final String status;
  final String? rawStatus;
  final List<RefundStepModel> steps;
  final String? nextAction;
  final PaymentProofModel? paymentProof;
  final String? comment;
  final String createdAt;
  final String? approvedAt;
  final String? paidAt;
  final String? createdByName;

  RefundDetailResponse({
    required this.id,
    this.reference,
    this.bookingType,
    required this.bookingId,
    this.bookingReference,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    this.percent,
    this.tierLabel,
    required this.reason,
    this.reasonLabel,
    this.reasonSubtitle,
    required this.status,
    this.rawStatus,
    this.steps = const [],
    this.nextAction,
    this.paymentProof,
    this.comment,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
    this.createdByName,
  });

  factory RefundDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      return RefundDetailResponse(
        id: _toString(json['id']) ?? '',
        reference: _toString(json['reference']),
        bookingType: _toString(json['booking_type']),
        bookingId: _toString(json['booking_id']) ?? '',
        bookingReference: _toString(json['booking_reference']),
        customerName: _toString(json['customer_name']) ?? 'Unknown',
        customerPhone: _toString(json['customer_phone']) ?? '',
        amount: _toInt(json['amount']),
        percent: _toDouble(json['percent']),
        tierLabel: _toString(json['tier_label']),
        reason: _toString(json['reason']) ?? 'other',
        reasonLabel: _toString(json['reason_label']),
        reasonSubtitle: _toString(json['reason_subtitle']),
        status: _toString(json['status']) ?? 'requested',
        rawStatus: _toString(json['raw_status']),
        steps: (json['steps'] as List?)
                ?.map((e) =>
                    RefundStepModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        nextAction: _toString(json['next_action']),
        paymentProof: json['payment_proof'] is Map
            ? PaymentProofModel.fromJson(
                json['payment_proof'] as Map<String, dynamic>)
            : null,
        comment: _toString(json['comment']),
        createdAt: _toString(json['created_at']) ?? '',
        approvedAt: _toString(json['approved_at']),
        paidAt: _toString(json['paid_at']),
        createdByName: _toString(json['created_by_name']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundDetailResponse: $e');
      rethrow;
    }
  }

  Refund toEntity() {
    final proof = paymentProof;
    return Refund(
      id: id,
      reference: reference,
      amount: amount,
      status: status,
      rawStatus: rawStatus,
      bookingId: bookingId,
      bookingReference: bookingReference,
      bookingType: bookingType,
      customer: RefundCustomer(name: customerName, phone: customerPhone),
      tier: tierLabel ?? (percent != null ? '${percent!.round()}%' : 'N/A'),
      percent: percent,
      reason: reason,
      reasonLabel: reasonLabel,
      reasonSubtitle: reasonSubtitle,
      notes: comment ?? '',
      createdAt: createdAt,
      approvedAt: approvedAt,
      paidAt: paidAt,
      utr: proof?.reference ?? '',
      proof: proof?.onFile ?? false,
      steps: steps.map((s) => s.toEntity()).toList(),
      nextAction: nextAction,
      paymentProof: proof?.toEntity(),
      createdByName: createdByName,
    );
  }
}

/// Refund model from the list (feed) response — flat customer fields.
class RefundModel {
  final String id;
  final String? reference;
  final String kind;
  final String? bookingType;
  final String bookingId;
  final String? bookingReference;
  final String customerName;
  final String customerPhone;
  final int amount;
  final double? percent;
  final String? tierLabel;
  final String reason;
  final String? reasonLabel;
  final String status;
  final String? rawStatus;
  final String? comment;
  final String createdAt;
  final String? approvedAt;
  final String? paidAt;

  RefundModel({
    required this.id,
    this.reference,
    required this.kind,
    this.bookingType,
    required this.bookingId,
    this.bookingReference,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    this.percent,
    this.tierLabel,
    required this.reason,
    this.reasonLabel,
    required this.status,
    this.rawStatus,
    this.comment,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    try {
      return RefundModel(
        id: _toString(json['id']) ?? '',
        reference: _toString(json['reference']),
        kind: _toString(json['kind']) ?? 'refund',
        bookingType: _toString(json['booking_type']),
        bookingId: _toString(json['booking_id']) ?? '',
        bookingReference: _toString(json['booking_reference']),
        customerName: _toString(json['customer_name']) ?? 'Unknown',
        customerPhone: _toString(json['customer_phone']) ?? '',
        amount: _toInt(json['amount']),
        percent: _toDouble(json['percent']),
        tierLabel: _toString(json['tier_label']),
        reason: _toString(json['reason']) ?? '',
        reasonLabel: _toString(json['reason_label']),
        status: _toString(json['status']) ?? 'requested',
        rawStatus: _toString(json['raw_status']),
        comment: _toString(json['comment']),
        createdAt: _toString(json['created_at']) ?? '',
        approvedAt: _toString(json['approved_at']),
        paidAt: _toString(json['paid_at']),
      );
    } catch (e) {
      debugPrint('Error parsing RefundModel: $e');
      rethrow;
    }
  }

  Refund toEntity() {
    return Refund(
      // Synthesized requests have null id/reference; fall back to the booking
      // reference so the row still has a stable identity for the list.
      id: id.isNotEmpty ? id : (bookingReference ?? ''),
      reference: reference,
      kind: kind,
      amount: amount,
      status: status,
      rawStatus: rawStatus,
      bookingId: bookingId,
      bookingReference: bookingReference,
      bookingType: bookingType,
      customer: RefundCustomer(name: customerName, phone: customerPhone),
      tier: tierLabel ?? (percent != null ? '${percent!.round()}%' : 'N/A'),
      percent: percent,
      reason: reason,
      reasonLabel: reasonLabel,
      notes: comment ?? '',
      createdAt: createdAt,
      approvedAt: approvedAt,
      paidAt: paidAt,
      utr: '',
      proof: false,
    );
  }
}

/// A single step in the refund lifecycle stepper.
class RefundStepModel {
  final String key;
  final String label;
  final bool done;
  final String? at;

  RefundStepModel({
    required this.key,
    required this.label,
    required this.done,
    this.at,
  });

  factory RefundStepModel.fromJson(Map<String, dynamic> json) {
    return RefundStepModel(
      key: _toString(json['key']) ?? '',
      label: _toString(json['label']) ?? '',
      done: _toBool(json['done']),
      at: _toString(json['at']),
    );
  }

  RefundStep toEntity() =>
      RefundStep(key: key, label: label, done: done, at: at);
}

/// Payment-proof object on the detail payload.
class PaymentProofModel {
  final String? reference;
  final String? screenshotUrl;
  final bool onFile;
  final bool requiredBeforePaid;

  PaymentProofModel({
    this.reference,
    this.screenshotUrl,
    this.onFile = false,
    this.requiredBeforePaid = true,
  });

  factory PaymentProofModel.fromJson(Map<String, dynamic> json) {
    return PaymentProofModel(
      reference: _toString(json['reference']),
      screenshotUrl: _toString(json['screenshot_url']),
      onFile: _toBool(json['on_file']),
      requiredBeforePaid: _toBool(json['required_before_paid']),
    );
  }

  RefundPaymentProof toEntity() => RefundPaymentProof(
        reference: reference,
        screenshotUrl: screenshotUrl,
        onFile: onFile,
        requiredBeforePaid: requiredBeforePaid,
      );
}

// Helper functions
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return double.parse(value).round();
    } catch (_) {
      return 0;
    }
  }
  return 0;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
}
