import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/settlement_response_model.dart';

class SettlementsApi {
  late Dio _dio;

  static const String _basePath = '/api/booking/v1/admin/settlements';

  SettlementsApi() {
    _dio = HttpClient().dio;
  }

  /// Get pending settlements for a shop: GET /api/booking/v1/admin/settlements/{shop_id}/pending/
  Future<SettlementPendingResponse> getPendingSettlements(String shopId) async {
    try {
      final response = await _dio.get('$_basePath/$shopId/pending/');
      return SettlementPendingResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create payout for a shop: POST /api/booking/v1/admin/settlements/{shop_id}/payout/
  Future<PayoutResponse> createPayout(
    String shopId, {
    String? utr,
    String? notes,
  }) async {
    try {
      final request = CreatePayoutRequest(utr: utr, notes: notes);
      final response = await _dio.post(
        '$_basePath/$shopId/payout/',
        data: request.toJson(),
      );
      return PayoutResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payout history for a shop: GET /api/booking/v1/admin/settlements/{shop_id}/history/
  Future<SettlementHistoryResponse> getPayoutHistory(String shopId) async {
    try {
      final response = await _dio.get('$_basePath/$shopId/history/');
      return SettlementHistoryResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get settlements overview (all shops): GET /api/booking/v1/admin/settlements/
  Future<SettlementOverviewResponse> getSettlementsOverview() async {
    try {
      final response = await _dio.get(_basePath);
      return SettlementOverviewResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DIO errors and convert to user-friendly messages
  Exception _handleError(DioException e) {
    String message = 'Error fetching settlements';

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 400) {
        message = (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : 'No pending settlements to create payout';
      } else if (statusCode == 409) {
        message = 'Payout already being created. Please try again.';
      } else if (statusCode == 403) {
        message = 'You do not have permission to access settlements';
      } else if (statusCode == 404) {
        message = 'Settlement not found';
      } else if (statusCode == 500) {
        message = 'Server error. Please try again.';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your network.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout. Please try again.';
    }

    return Exception(message);
  }
}
