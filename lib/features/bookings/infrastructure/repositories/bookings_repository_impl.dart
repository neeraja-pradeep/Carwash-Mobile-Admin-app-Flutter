import 'package:flutter/foundation.dart';

import '../../domain/entities/carwash_booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../data_sources/bookings_api.dart';
import '../models/booking_detail_response_model.dart';
import '../models/refund_response_model.dart';

/// Fulfils [BookingsRepository] from the API.
class BookingsRepositoryImpl implements BookingsRepository {
  BookingsRepositoryImpl({BookingsApi? api})
      : _api = api ?? BookingsApi();

  final BookingsApi _api;

  @override
  Future<List<CarwashBooking>> fetchBookings({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? dateRange,
    String? timeOfDay,
    List<String>? statusChips,
    List<String>? shops,
    String? assignment,
    String? sort,
  }) async {
    try {
      final response = await _api.getBookings(
        page: page,
        pageSize: pageSize,
        search: search,
        dateRange: dateRange,
        timeOfDay: timeOfDay,
        statusChips: statusChips,
        shops: shops,
        assignment: assignment,
        sort: sort,
      );

      return response.results.map((model) => model.toCarwashEntity()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching bookings: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<BookingDetailResponse> getBookingDetail(int id) async {
    try {
      return await _api.getBookingDetail(id);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching booking detail: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<AssignableDriversResponse> getAssignableDrivers(int id) async {
    try {
      return await _api.getAssignableDrivers(id);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching assignable drivers: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> assignDriver(int bookingId, int driverId) async {
    try {
      await _api.assignDriver(bookingId, driverId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR assigning driver: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> assignMe(int bookingId) async {
    try {
      await _api.assignMe(bookingId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR assigning me: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updateWashingStatus(int bookingId, String washingStatus) async {
    try {
      await _api.updateWashingStatus(bookingId, washingStatus);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating washing status: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDamageCheck(int bookingId) async {
    try {
      return await _api.getDamageCheck(bookingId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching damage check: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> saveDamageCheck(
    int bookingId, {
    required String stage,
    required bool checked,
    required String issuesFound,
    List<String>? damageTypes,
    List<String>? panels,
    String? notes,
  }) async {
    try {
      await _api.saveDamageCheck(
        bookingId,
        stage: stage,
        checked: checked,
        issuesFound: issuesFound,
        damageTypes: damageTypes,
        panels: panels,
        notes: notes,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR saving damage check: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(int bookingId, {String? reason}) async {
    try {
      await _api.cancelBooking(bookingId, reason: reason);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR cancelling booking: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> refundBooking(int bookingId, {String? reason}) async {
    try {
      await _api.refundBooking(bookingId, reason: reason);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR refunding booking: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<RefundSummaryResponse> getRefundSummary(int bookingId) async {
    try {
      return await _api.getRefundSummary(bookingId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching refund summary: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<RefundResponse> createRefund(
    int bookingId, {
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  }) async {
    try {
      return await _api.createRefund(
        bookingId,
        percent: percent,
        amount: amount,
        reason: reason,
        comment: comment,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating refund: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
