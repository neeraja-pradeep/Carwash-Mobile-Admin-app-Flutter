import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/driver_response_model.dart';

/// Remote data source for the Team feature — §8 of docs/api_admin.md.
///
/// Drivers and inspectors share identical endpoints; the only path difference
/// is the `drivers` / `inspectors` segment, selected via [isInspector].
class DriversApi {
  late Dio _dio;

  static const String _base = '/api/shop/v1/';

  DriversApi() {
    _dio = HttpClient().dio;
  }

  String _workersPath(bool isInspector) =>
      '$_base${isInspector ? 'inspectors' : 'drivers'}/';

  // ── List ───────────────────────────────────────────────────────────────────

  /// GET /api/shop/v1/drivers/ (or inspectors/) with optional `?status=`.
  Future<DriverListResponse> listWorkers({
    required bool isInspector,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        _workersPath(isInspector),
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return DriverListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DriverListResponse> listDrivers({String? status}) =>
      listWorkers(isInspector: false, status: status);

  Future<DriverListResponse> listInspectors({String? status}) =>
      listWorkers(isInspector: true, status: status);

  // ── Detail ───────────────────────────────────────────────────────────────────

  /// GET /api/shop/v1/drivers/{id}/ — detail (list fields + active_job/week/etc.).
  Future<FieldDriverModel> getWorkerDetail(
    String id, {
    bool isInspector = false,
  }) async {
    try {
      final response = await _dio.get('${_workersPath(isInspector)}$id/');
      return FieldDriverModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FieldDriverModel> getDriverDetail(String id) =>
      getWorkerDetail(id, isInspector: false);

  // ── Hire ───────────────────────────────────────────────────────────────────

  /// POST /api/shop/v1/drivers/hire/ — creates the worker (active, no SMS).
  ///
  /// [subRole] is sent for drivers only (omit for inspectors).
  /// Throws a `Exception('A user with this phone already exists')` on 409.
  Future<FieldDriverModel> hireWorker({
    required bool isInspector,
    required String fullName,
    required String phone,
    String? email,
    String? subRole,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) async {
    try {
      final body = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (!isInspector && subRole != null) 'sub_role': subRole,
        'vehicle_classes': canonicalVehicleClasses(vehicleClasses),
        if (licenseNumber.isNotEmpty) 'license_number': licenseNumber,
        if (licenseExpiry.isNotEmpty) 'license_expiry': licenseExpiry,
        'license_verified': licenseVerified,
      };
      final response = await _dio.post(
        '${_workersPath(isInspector)}hire/',
        data: body,
      );
      return FieldDriverModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('A user with this phone number already exists.');
      }
      throw _handleError(e);
    }
  }

  Future<FieldDriverModel> hireDriver({
    required String fullName,
    required String phone,
    String? email,
    String? subRole,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) =>
      hireWorker(
        isInspector: false,
        fullName: fullName,
        phone: phone,
        email: email,
        subRole: subRole,
        vehicleClasses: vehicleClasses,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseVerified: licenseVerified,
      );

  Future<FieldDriverModel> hireInspector({
    required String fullName,
    required String phone,
    String? email,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) =>
      hireWorker(
        isInspector: true,
        fullName: fullName,
        phone: phone,
        email: email,
        vehicleClasses: vehicleClasses,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseVerified: licenseVerified,
      );

  // ── Update (PATCH) ───────────────────────────────────────────────────────────

  /// PATCH /api/shop/v1/drivers/{id}/ — partial update of both the worker row
  /// and linked user account. Pass only changed fields.
  ///
  /// The status field name differs by worker type — pass [status] and it is
  /// serialised as `driver_status` / `inspector_status`. `license_expiry` must
  /// be an ISO `YYYY-MM-DD` on PATCH.
  Future<FieldDriverModel> updateWorker(
    String id, {
    required bool isInspector,
    String? fullName,
    String? email,
    String? status,
    String? subRole,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
    String? title,
  }) async {
    try {
      final body = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (status != null)
          (isInspector ? 'inspector_status' : 'driver_status'): status,
        if (!isInspector && subRole != null) 'sub_role': subRole,
        if (vehicleClasses != null)
          'vehicle_classes': canonicalVehicleClasses(vehicleClasses),
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (licenseExpiry != null) 'license_expiry': licenseExpiry,
        if (licenseVerified != null) 'license_verified': licenseVerified,
        if (phone != null) 'phone': phone,
        if (title != null) 'title': title,
      };
      final response = await _dio.patch(
        '${_workersPath(isInspector)}$id/',
        data: body,
      );
      return FieldDriverModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FieldDriverModel> updateDriver(
    String id, {
    String? fullName,
    String? email,
    String? status,
    String? subRole,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
    String? title,
  }) =>
      updateWorker(
        id,
        isInspector: false,
        fullName: fullName,
        email: email,
        status: status,
        subRole: subRole,
        vehicleClasses: vehicleClasses,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseVerified: licenseVerified,
        phone: phone,
        title: title,
      );

  Future<FieldDriverModel> updateInspector(
    String id, {
    String? fullName,
    String? email,
    String? status,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
    String? title,
  }) =>
      updateWorker(
        id,
        isInspector: true,
        fullName: fullName,
        email: email,
        status: status,
        vehicleClasses: vehicleClasses,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseVerified: licenseVerified,
        phone: phone,
        title: title,
      );

  // ── Delete ───────────────────────────────────────────────────────────────────

  /// DELETE /api/shop/v1/drivers/{id}/ — removes the worker.
  Future<void> deleteWorker(String id, {required bool isInspector}) async {
    try {
      await _dio.delete('${_workersPath(isInspector)}$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDriver(String id) =>
      deleteWorker(id, isInspector: false);

  Future<void> deleteInspector(String id) =>
      deleteWorker(id, isInspector: true);

  // ── Documents ─────────────────────────────────────────────────────────────────

  /// POST /api/shop/v1/drivers/{id}/documents/ — multipart upload of one side.
  Future<DriverDocumentModel> uploadDocument(
    String id, {
    required bool isInspector,
    required String filePath,
    required String kind,
    String side = 'front',
    String? name,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'kind': kind,
        'side': side,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      final response = await _dio.post(
        '${_workersPath(isInspector)}$id/documents/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return DriverDocumentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH /api/shop/v1/drivers/{id}/documents/{doc_id}/ — verify / rename.
  Future<DriverDocumentModel> patchDocument(
    String id,
    String docId, {
    required bool isInspector,
    bool? frontVerified,
    bool? backVerified,
    bool? verified,
    String? name,
  }) async {
    try {
      final body = <String, dynamic>{
        if (frontVerified != null) 'front_verified': frontVerified,
        if (backVerified != null) 'back_verified': backVerified,
        if (verified != null) 'verified': verified,
        if (name != null) 'name': name,
      };
      final response = await _dio.patch(
        '${_workersPath(isInspector)}$id/documents/$docId/',
        data: body,
      );
      return DriverDocumentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE /api/shop/v1/drivers/{id}/documents/{doc_id}/ — removes the doc.
  Future<void> deleteDocument(
    String id,
    String docId, {
    required bool isInspector,
  }) async {
    try {
      await _dio.delete('${_workersPath(isInspector)}$id/documents/$docId/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handling ─────────────────────────────────────────────────────────

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
            errorData['email'] ??
            errorData['phone'] ??
            'An error occurred';
        return Exception(errorMessage.toString());
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
