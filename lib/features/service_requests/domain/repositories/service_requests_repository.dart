import '../entities/service_request.dart';
import '../../infrastructure/models/driver_inspection_detail_response_model.dart';
import '../../infrastructure/models/create_request_response_model.dart';

/// Contract for reading service requests. Pure abstract — no implementation.
abstract class ServiceRequestsRepository {
  /// Fetch service requests with optional filters, sorting, and pagination.
  Future<List<ServiceRequest>> fetchServiceRequests({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? requestType,
    String? status,
    String? sort,
    String? dateRange,
  });

  /// Get detail for single request
  Future<DriverInspectionDetailResponse> getDetail(int id);

  /// Get assignable workers for a request
  Future<AssignableWorkersResponse> getAssignableWorkers(int id, {int? slotId});

  /// Assign worker to request
  Future<void> assignWorker({
    required int id,
    required int workerId,
    required int slotId,
    required String workerType,
  });

  /// Update request status
  Future<void> updateStatus({
    required int id,
    required String status,
    String? note,
    String? quotedFee,
  });

  /// Mark request as arrived
  Future<void> markArrived(int id);

  /// Verify start OTP
  Future<void> verifyStartOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  });

  /// Verify end OTP
  Future<void> verifyEndOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  });

  /// Cancel request
  Future<void> cancelRequest(int id);

  /// Search existing customers
  Future<CustomerListResponse> searchCustomers(String query);

  /// Create a new customer account
  Future<CreateCustomerResponse> createCustomer({
    required String phone,
    required String fullName,
    String? otpCode,
    String? email,
  });

  /// Create a new service request (driver hire or inspection)
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
  });
}
