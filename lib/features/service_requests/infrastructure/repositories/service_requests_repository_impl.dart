import 'package:flutter/foundation.dart';

import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_requests_repository.dart';
import '../data_sources/driver_inspection_requests_api.dart';
import '../data_sources/create_request_api.dart';
import '../models/driver_inspection_detail_response_model.dart';
import '../models/create_request_response_model.dart';

/// Fulfils [ServiceRequestsRepository] from the API.
class ServiceRequestsRepositoryImpl implements ServiceRequestsRepository {
  ServiceRequestsRepositoryImpl({
    DriverInspectionRequestsApi? api,
    CreateRequestApi? createApi,
  })  : _api = api ?? DriverInspectionRequestsApi(),
        _createApi = createApi ?? CreateRequestApi();

  final DriverInspectionRequestsApi _api;
  final CreateRequestApi _createApi;
  String _lastQueryKey = '';
  Future<List<ServiceRequest>>? _lastFuture;
  String _lastDetailKey = '';
  Future<DriverInspectionDetailResponse>? _lastDetailFuture;
  String _lastAssignableWorkersKey = '';
  Future<AssignableWorkersResponse>? _lastAssignableWorkersFuture;

  /// Creates a cache key from the query parameters.
  String _getCacheKey({
    required int page,
    required int pageSize,
    String? search,
    String? requestType,
    String? status,
    String? sort,
    String? dateRange,
  }) {
    return '$page|$pageSize|$search|$requestType|$status|$sort|$dateRange';
  }

  @override
  Future<List<ServiceRequest>> fetchServiceRequests({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? requestType,
    String? status,
    String? sort,
    String? dateRange,
  }) async {
    final queryKey = _getCacheKey(
      page: page,
      pageSize: pageSize,
      search: search,
      requestType: requestType,
      status: status,
      sort: sort,
      dateRange: dateRange,
    );

    // Return cached future if query hasn't changed
    if (queryKey == _lastQueryKey && _lastFuture != null) {
      return _lastFuture!;
    }

    _lastQueryKey = queryKey;

    // Create and cache the future
    _lastFuture = _fetchFromApi(
      page: page,
      pageSize: pageSize,
      search: search,
      requestType: requestType,
      status: status,
      sort: sort,
      dateRange: dateRange,
    );

    return _lastFuture!;
  }

  Future<List<ServiceRequest>> _fetchFromApi({
    required int page,
    required int pageSize,
    String? search,
    String? requestType,
    String? status,
    String? sort,
    String? dateRange,
  }) async {
    try {
      final response = await _api.getRequests(
        page: page,
        pageSize: pageSize,
        search: search,
        requestType: requestType,
        status: status,
        sort: sort,
        dateRange: dateRange,
      );

      return response.results.map((r) => r.toDomain()).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching service requests: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get detail for single request (cached)
  Future<DriverInspectionDetailResponse> getDetail(int id) async {
    final detailKey = id.toString();

    if (detailKey == _lastDetailKey && _lastDetailFuture != null) {
      return _lastDetailFuture!;
    }

    _lastDetailKey = detailKey;
    _lastDetailFuture = _fetchDetailFromApi(id);

    return _lastDetailFuture!;
  }

  Future<DriverInspectionDetailResponse> _fetchDetailFromApi(int id) async {
    try {
      return await _api.getDetail(id);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching detail: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get assignable workers (cached)
  Future<AssignableWorkersResponse> getAssignableWorkers(
    int id, {
    int? slotId,
  }) async {
    final workersKey = '$id|$slotId';

    if (workersKey == _lastAssignableWorkersKey &&
        _lastAssignableWorkersFuture != null) {
      return _lastAssignableWorkersFuture!;
    }

    _lastAssignableWorkersKey = workersKey;
    _lastAssignableWorkersFuture =
        _fetchAssignableWorkersFromApi(id, slotId: slotId);

    return _lastAssignableWorkersFuture!;
  }

  Future<AssignableWorkersResponse> _fetchAssignableWorkersFromApi(
    int id, {
    int? slotId,
  }) async {
    try {
      return await _api.getAssignableWorkers(id, slotId: slotId);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching assignable workers: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Assign worker to request (NO caching)
  Future<void> assignWorker({
    required int id,
    required int workerId,
    required int slotId,
    required String workerType,
  }) async {
    try {
      await _api.assignWorker(
        id: id,
        workerId: workerId,
        slotId: slotId,
        workerType: workerType,
      );
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR assigning worker: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Update request status (NO caching)
  Future<void> updateStatus({
    required int id,
    required String status,
    String? note,
    String? quotedFee,
  }) async {
    try {
      await _api.updateStatus(
        id: id,
        status: status,
        note: note,
        quotedFee: quotedFee,
      );
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating status: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Mark request as arrived (NO caching)
  Future<void> markArrived(int id) async {
    try {
      await _api.markArrived(id);
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR marking arrived: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Verify start OTP (NO caching)
  Future<void> verifyStartOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    try {
      await _api.verifyStartOtp(
        id: id,
        otp: otp,
        latitude: latitude,
        longitude: longitude,
        locationText: locationText,
      );
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR verifying start OTP: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Verify end OTP (NO caching)
  Future<void> verifyEndOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    try {
      await _api.verifyEndOtp(
        id: id,
        otp: otp,
        latitude: latitude,
        longitude: longitude,
        locationText: locationText,
      );
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR verifying end OTP: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel request (NO caching)
  @override
  Future<void> cancelRequest(int id) async {
    try {
      await _api.cancelRequest(id);
      // Invalidate detail cache
      _lastDetailKey = '';
      _lastDetailFuture = null;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR cancelling request: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Search existing customers
  @override
  Future<CustomerListResponse> searchCustomers(String query) async {
    try {
      return await _createApi.searchCustomers(query);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR searching customers: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new customer account
  @override
  Future<CreateCustomerResponse> createCustomer({
    required String phone,
    required String fullName,
    String? otpCode,
    String? email,
  }) async {
    try {
      return await _createApi.createCustomer(
        phone: phone,
        fullName: fullName,
        otpCode: otpCode,
        email: email,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating customer: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new service request (driver hire or inspection)
  @override
  Future<CreateRequestResponse> createRequest({
    required int customerId,
    required String requestType,
    String? tripType,
    String? inspectionType,
    String? vehicleText,
    int? carId,
    required String appointmentDate,
    int? startSlot,
    String? startTime,
    String? addressText,
    double? latitude,
    double? longitude,
    String? dropAddressText,
    double? dropLatitude,
    double? dropLongitude,
    String? quotedFee,
    String? customerNote,
    String? hourlyPackage,
    int? requestedHours,
  }) async {
    try {
      return await _createApi.createRequest(
        customerId: customerId,
        requestType: requestType,
        tripType: tripType,
        inspectionType: inspectionType,
        vehicleText: vehicleText,
        carId: carId,
        appointmentDate: appointmentDate,
        startSlot: startSlot,
        startTime: startTime,
        addressText: addressText,
        latitude: latitude,
        longitude: longitude,
        dropAddressText: dropAddressText,
        dropLatitude: dropLatitude,
        dropLongitude: dropLongitude,
        quotedFee: quotedFee,
        customerNote: customerNote,
        hourlyPackage: hourlyPackage,
        requestedHours: requestedHours,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating request: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
