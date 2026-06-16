import '../entities/service_request.dart';

/// Contract for reading service requests. Pure abstract — no implementation.
abstract class ServiceRequestsRepository {
  /// All service requests, newest first.
  Future<List<ServiceRequest>> fetchServiceRequests();
}
