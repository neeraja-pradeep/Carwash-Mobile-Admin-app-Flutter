import 'package:flutter/foundation.dart';
import '../../domain/entities/refund.dart';
import '../../domain/repositories/refunds_repository.dart';
import '../data_sources/refunds_api.dart';

/// Fulfils [RefundsRepository] from the API. Remote-first; rethrows on error.
class RefundsRepositoryImpl implements RefundsRepository {
  RefundsRepositoryImpl({RefundsApi? api}) : _api = api ?? RefundsApi();

  final RefundsApi _api;

  @override
  Future<List<Refund>> fetchRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
    int days = 30,
  }) async {
    try {
      final response = await _api.getRefunds(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        reason: reason,
        sort: sort,
        days: days,
      );
      return response.results.map((model) => model.toEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching refunds: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund?> getRefundDetail(String idOrReference) async {
    try {
      final response = await _api.getRefundDetailByRef(idOrReference);
      return response.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching refund detail: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund> approve({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  }) async {
    try {
      final res = await _api.approveRefund(
        bookingReference: bookingReference,
        percent: percent,
        amount: amount,
        reason: reason,
        comment: comment,
      );
      return res.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR approving refund: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund> markPaid({
    required String refundRef,
    required String paymentProofReference,
    String? screenshotPath,
    bool manual = false,
  }) async {
    try {
      final res = await _api.markPaidRefund(
        refundRef: refundRef,
        paymentProofReference: paymentProofReference,
        screenshotPath: screenshotPath,
        manual: manual,
      );
      return res.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR marking refund paid: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund> createStandalone({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
    bool manual = false,
    String? paymentKind,
  }) async {
    try {
      final res = await _api.createRefund(
        bookingReference: bookingReference,
        percent: percent,
        amount: amount,
        reason: reason,
        comment: comment,
        manual: manual,
        paymentKind: paymentKind,
      );
      return res.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating refund: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Refund> decline({
    required String bookingReference,
    String? reason,
    String? comment,
  }) async {
    try {
      final res = await _api.declineRefund(
        bookingReference: bookingReference,
        reason: reason,
        comment: comment,
      );
      return res.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR declining refund: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
