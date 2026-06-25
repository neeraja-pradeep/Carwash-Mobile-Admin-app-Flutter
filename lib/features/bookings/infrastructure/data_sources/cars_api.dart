import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/manual_booking_models.dart';

/// Data source for creating customer vehicles (`Cars`) used by the manual
/// New Booking flow's "add new vehicle" step.
///
/// `POST /api/accounts/v1/cars/` with `{ user_id, brand_model, registration,
/// car_type }`.
class CarsApi {
  late Dio _dio;

  static const String _carsPath = '/api/accounts/v1/cars/';

  CarsApi() {
    _dio = HttpClient().dio;
  }

  /// Create a vehicle for a customer and return the created `Cars` record.
  Future<CreatedVehicle> createVehicle({
    required int userId,
    required String brandModel,
    required String registration,
    String? carType,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'brand_model': brandModel,
        'registration': registration,
        if (carType != null && carType.isNotEmpty) 'car_type': carType,
      };

      final response = await _dio.post(_carsPath, data: body);

      return CreatedVehicle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }

      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        if (statusCode == 400 && errorData.isNotEmpty) {
          final errors = <String>[];
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors.add('${key.replaceAll('_', ' ')}: ${value.first}');
            } else if (value is String) {
              errors.add('${key.replaceAll('_', ' ')}: $value');
            }
          });
          if (errors.isNotEmpty) {
            return Exception(errors.join('\n'));
          }
        }

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
