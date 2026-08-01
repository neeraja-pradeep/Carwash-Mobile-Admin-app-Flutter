import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/shop_hours_models.dart';

/// Backs the "Manage Hours & Slots" screen — see `docs/api_admin.md` §3.4.
class ShopHoursApi {
  late Dio _dio;

  static const String _weeklyBusinessPath =
      '/api/shop/v1/shop-weekly-businesses/';
  static const String _slotBreaksPath = '/api/shop/v1/shop-slot-breaks/';
  static const String _slotsPath = '/api/shop/v1/slots/';
  static const String _holidaysPath = '/api/shop/v1/holidays/';

  ShopHoursApi() {
    _dio = HttpClient().dio;
  }

  /// The fixed 30-minute reference grid: `GET /api/shop/v1/slots/`.
  /// Unpaginated — returns every slot in one call.
  Future<List<SlotModel>> getSlots() async {
    try {
      final response = await _dio.get(_slotsPath);
      return (response.data as List<dynamic>)
          .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `GET /api/shop/v1/shop-weekly-businesses/?shop={shopId}`.
  Future<List<WeeklyBusinessModel>> getWeeklyBusinesses(String shopId) async {
    try {
      final response = await _dio.get(
        _weeklyBusinessPath,
        queryParameters: {'shop': shopId},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['results'] as List<dynamic>)
          .map((r) => WeeklyBusinessModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `POST /api/shop/v1/shop-weekly-businesses/`.
  Future<WeeklyBusinessModel> createWeeklyBusiness({
    required String shopId,
    required int weekday,
    required int openingSlotId,
    required int closingSlotId,
  }) async {
    try {
      final response = await _dio.post(
        _weeklyBusinessPath,
        data: {
          'shop': int.parse(shopId),
          'weekday': weekday,
          'opening_slot': openingSlotId,
          'closing_slot': closingSlotId,
        },
      );
      return WeeklyBusinessModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `PATCH /api/shop/v1/shop-weekly-businesses/{id}/`.
  Future<WeeklyBusinessModel> updateWeeklyBusiness({
    required int id,
    required int openingSlotId,
    required int closingSlotId,
  }) async {
    try {
      final response = await _dio.patch(
        '$_weeklyBusinessPath$id/',
        data: {
          'opening_slot': openingSlotId,
          'closing_slot': closingSlotId,
        },
      );
      return WeeklyBusinessModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `DELETE /api/shop/v1/shop-weekly-businesses/{id}/` — turns the day OFF
  /// (there is no separate "closed" flag; an absent row means off).
  Future<void> deleteWeeklyBusiness(int id) async {
    try {
      await _dio.delete('$_weeklyBusinessPath$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `GET /api/shop/v1/shop-slot-breaks/?shop={shopId}` — every recurring
  /// break for the shop, across all weekdays.
  Future<List<SlotBreakModel>> getSlotBreaks(String shopId) async {
    try {
      final response = await _dio.get(
        _slotBreaksPath,
        queryParameters: {'shop': shopId},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['results'] as List<dynamic>)
          .map((r) => SlotBreakModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `POST /api/shop/v1/shop-slot-breaks/set-day/` — replaces ALL breaks for
  /// one `(shop, weekday)` with [slotIds] in a single call.
  Future<void> setDayBreaks({
    required String shopId,
    required int weekday,
    required List<int> slotIds,
  }) async {
    try {
      await _dio.post(
        '${_slotBreaksPath}set-day/',
        data: {
          'shop': int.parse(shopId),
          'weekday': weekday,
          'slot_ids': slotIds,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `GET /api/shop/v1/holidays/?shop={shopId}`.
  Future<List<HolidayApiModel>> getHolidays(String shopId) async {
    try {
      final response = await _dio.get(
        _holidaysPath,
        queryParameters: {'shop': shopId},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['results'] as List<dynamic>)
          .map((r) => HolidayApiModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `POST /api/shop/v1/holidays/`.
  Future<HolidayApiModel> createHoliday({
    required String date,
    required String label,
    required List<int> shopIds,
  }) async {
    try {
      final response = await _dio.post(
        _holidaysPath,
        data: {
          'date': date,
          'label': label,
          'shops': shopIds,
        },
      );
      return HolidayApiModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// `DELETE /api/shop/v1/holidays/{id}/`.
  Future<void> deleteHoliday(int id) async {
    try {
      await _dio.delete('$_holidaysPath$id/');
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
