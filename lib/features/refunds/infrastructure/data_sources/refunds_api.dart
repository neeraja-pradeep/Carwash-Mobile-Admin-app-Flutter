import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/refund_response_model.dart';

class RefundsApi {
  late Dio _dio;

  static const String _refundsPath = '/api/booking/v1/admin/refunds/';

  RefundsApi() {
    _dio = HttpClient().dio;
  }

  /// Get all refunds (paginated) with optional filters.
  ///
  /// [days] sets the `created_at` window (default 30; `0`/`all` disables).
  Future<RefundListResponse> getRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
    int days = 30,
  }) async {
    try {
      final params = {
        'page': page,
        'page_size': pageSize,
        'days': days,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      final response = await _dio.get(_refundsPath, queryParameters: params);

      return RefundListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get refund detail by numeric id or `RF-…` reference.
  /// GET /api/booking/v1/admin/refunds/detail/{id_or_reference}/
  Future<RefundDetailResponse> getRefundDetailByRef(String idOrReference) async {
    try {
      final response = await _dio.get('${_refundsPath}detail/$idOrReference/');

      return RefundDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve a customer refund request.
  /// POST /api/booking/v1/admin/refunds/approve/
  Future<RefundDetailResponse> approveRefund({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  }) async {
    return _post('approve/', {
      'booking_reference': bookingReference,
      if (percent != null) 'percent': percent,
      if (amount != null) 'amount': amount,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// Mark an approved refund paid. Supports an optional screenshot via
  /// multipart. [refundRef] is the refund id or `RF-…` reference.
  /// POST /api/booking/v1/admin/refunds/mark-paid/
  Future<RefundDetailResponse> markPaidRefund({
    required String refundRef,
    required String paymentProofReference,
    String? screenshotPath,
    bool manual = false,
  }) async {
    try {
      final Object body;
      if (screenshotPath != null && screenshotPath.isNotEmpty) {
        body = FormData.fromMap({
          'refund': refundRef,
          'payment_proof_reference': paymentProofReference,
          if (manual) 'mode': 'manual',
          'screenshot': await MultipartFile.fromFile(screenshotPath),
        });
      } else {
        body = {
          'refund': refundRef,
          'payment_proof_reference': paymentProofReference,
          if (manual) 'mode': 'manual',
        };
      }

      final response = await _dio.post('${_refundsPath}mark-paid/', data: body);
      return _unwrapRefund(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Standalone create-by-reference. Issues directly to Paid.
  /// POST /api/booking/v1/admin/refunds/create/
  Future<RefundDetailResponse> createRefund({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
    bool manual = false,
    String? paymentKind,
  }) async {
    return _post('create/', {
      'booking_reference': bookingReference,
      if (percent != null) 'percent': percent,
      if (amount != null) 'amount': amount,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (manual) 'mode': 'manual',
      if (paymentKind != null && paymentKind.isNotEmpty)
        'payment_kind': paymentKind,
    });
  }

  /// Decline a refund request (terminal off-ramp).
  /// POST /api/booking/v1/admin/refunds/decline/
  Future<RefundDetailResponse> declineRefund({
    required String bookingReference,
    String? reason,
    String? comment,
  }) async {
    return _post('decline/', {
      'booking_reference': bookingReference,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// POSTs [body] to [suffix] under the refunds path and unwraps `{refund:{…}}`.
  Future<RefundDetailResponse> _post(
    String suffix,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post('$_refundsPath$suffix', data: body);
      return _unwrapRefund(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// The action endpoints wrap the detail payload as `{ "refund": { … } }`.
  /// Tolerate a bare payload too.
  RefundDetailResponse _unwrapRefund(dynamic data) {
    final map = data as Map<String, dynamic>;
    final refund = map['refund'];
    return RefundDetailResponse.fromJson(
      refund is Map<String, dynamic> ? refund : map,
    );
  }

  /// Get list response model (used for parsing paginated responses)
  RefundListResponse parseListResponse(Map<String, dynamic> data) {
    return RefundListResponse.fromJson(data);
  }

  /// Handle DioException and throw appropriate error
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }

      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        final errorMessage = errorData['error'] ??
            errorData['detail'] ??
            errorData['message'] ??
            'An error occurred';
        return Exception(errorMessage);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        return Exception(
          'Error ${e.response?.statusCode}: ${e.response?.statusMessage}',
        );
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.badCertificate:
        return Exception('Certificate error');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your internet.');
      case DioExceptionType.unknown:
        return Exception(e.message ?? 'Unknown error occurred');
    }
  }
}
