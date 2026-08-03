import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/promotion_response_model.dart';

/// Offers → Banners, backed by the `Promotion` viewset.
///
/// Writes go out as `multipart/form-data` whenever artwork is involved: the
/// serializer's `image` field is a file, and the server uploads it to BunnyCDN
/// and returns the derived `image_url` (which is read-only — there is no way to
/// set a URL without sending a file).
class PromotionsApi {
  PromotionsApi() {
    _dio = HttpClient().dio;
  }

  late Dio _dio;

  static const String _promotionsPath = '/api/shop/v1/promotions/';

  /// List banners (paginated).
  ///
  /// [lifecycle] is a comma-separated subset of
  /// `active`,`scheduled`,`inactive`,`expired`.
  /// [ordering] is `display_order` (default), `starts_at` or `created_at`,
  /// each optionally `-` prefixed.
  Future<PromotionListResponse> getPromotions({
    String? search,
    String? placement,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        _promotionsPath,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
          if (placement != null && placement.isNotEmpty) 'placement': placement,
          if (lifecycle != null && lifecycle.isNotEmpty) 'lifecycle': lifecycle,
          if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        },
      );
      return PromotionListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single banner by id (for the Edit form).
  Future<PromotionModel> getPromotionDetail(String id) async {
    try {
      final response = await _dio.get('$_promotionsPath$id/');
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a banner. [imagePath], when set, is uploaded as the `image` file.
  Future<PromotionModel> createPromotion(
    Map<String, dynamic> body, {
    String? imagePath,
  }) async {
    try {
      final response = await _dio.post(
        _promotionsPath,
        data: await _encode(body, imagePath: imagePath),
      );
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Partial-update a banner.
  ///
  /// Image handling mirrors the form's controls:
  /// - **replace** — pass [imagePath]; the old CDN file is deleted.
  /// - **remove** — pass [removeImage]; sends an empty `image` so the server
  ///   drops the file and nulls `image_url`.
  /// - **keep** — pass neither; `image` is omitted and the artwork is untouched.
  Future<PromotionModel> updatePromotion(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      final response = await _dio.patch(
        '$_promotionsPath$id/',
        data: await _encode(
          body,
          imagePath: imagePath,
          removeImage: removeImage,
        ),
      );
      return PromotionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a banner (204). The server also drops its CDN image.
  Future<void> deletePromotion(String id) async {
    try {
      await _dio.delete('$_promotionsPath$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fans the banner out to every active customer's bell feed (202).
  /// Rejected `400` when the banner is not active. Not idempotent — each call
  /// queues a fresh batch.
  Future<void> broadcastPromotion(String id) async {
    try {
      await _dio.post('$_promotionsPath$id/broadcast/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Picks the wire format: JSON when there is no artwork to send, multipart
  /// otherwise. `FormData` cannot carry nulls, so a removal is sent as an empty
  /// `image` value — which is what "present but empty" means to the serializer.
  Future<Object> _encode(
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage = false,
  }) async {
    if (imagePath == null && !removeImage) return body;

    final form = FormData();
    body.forEach((key, value) {
      if (value == null) return;
      form.fields.add(MapEntry(key, '$value'));
    });

    if (imagePath != null) {
      form.files.add(
        MapEntry('image', await MultipartFile.fromFile(imagePath)),
      );
    } else {
      form.fields.add(const MapEntry('image', ''));
    }
    return form;
  }

  /// Surfaces field-keyed 400 validation messages so the form can show a
  /// useful toast, falling back to transport-level errors.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      if (e.response?.statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final direct = data['error'] ?? data['detail'] ?? data['message'];
        if (direct != null) return Exception(direct.toString());

        for (final entry in data.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return Exception('${entry.key}: ${value.first}');
          }
          if (value is String && value.isNotEmpty) {
            return Exception('${entry.key}: $value');
          }
        }
        return Exception('An error occurred');
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
      default:
        return Exception(e.message ?? 'Unknown error occurred');
    }
  }
}
