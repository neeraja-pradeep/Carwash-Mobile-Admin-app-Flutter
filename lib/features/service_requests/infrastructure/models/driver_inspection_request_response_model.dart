import '../../domain/entities/service_request.dart';
import '../../../../core/status/service_request_status.dart';

/// Paginated driver/inspection requests list response from API.
class DriverInspectionRequestsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<DriverInspectionRequestModel> results;

  DriverInspectionRequestsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory DriverInspectionRequestsResponse.fromJson(Map<String, dynamic> json) {
    return DriverInspectionRequestsResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: ((json['results'] as List<dynamic>?) ?? [])
          .map((item) => DriverInspectionRequestModel.fromJson(
            item as Map<String, dynamic>,
          ))
          .toList(),
    );
  }

  int? getNextPage() {
    if (next == null) return null;
    try {
      final uri = Uri.parse(next!);
      return int.tryParse(uri.queryParameters['page'] ?? '');
    } catch (e) {
      return null;
    }
  }

  bool get hasNextPage => next != null;
}

/// Single driver/inspection request from the API.
class DriverInspectionRequestModel {
  final int id;
  final String reference;
  final String requestType; // 'driver' or 'inspection'
  final String? tripType;
  final String? inspectionType;
  final String title;
  final String vehicle;
  final String appointmentDate;
  final String startTime;
  final String durationLabel;
  final String addressText;
  final String? dropAddressText;
  final String amount;
  final bool isPaid;
  final String status; // 'new', 'contacted', 'assigned', 'arrived', 'in_progress', 'completed', 'cancelled'
  final String? assigneeName;
  final bool needsAssignee;
  final String customerName;
  final String customerPhone;

  DriverInspectionRequestModel({
    required this.id,
    required this.reference,
    required this.requestType,
    this.tripType,
    this.inspectionType,
    required this.title,
    required this.vehicle,
    required this.appointmentDate,
    required this.startTime,
    required this.durationLabel,
    required this.addressText,
    this.dropAddressText,
    required this.amount,
    required this.isPaid,
    required this.status,
    this.assigneeName,
    required this.needsAssignee,
    required this.customerName,
    required this.customerPhone,
  });

  factory DriverInspectionRequestModel.fromJson(Map<String, dynamic> json) {
    return DriverInspectionRequestModel(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      requestType: json['request_type'] as String? ?? 'driver',
      tripType: json['trip_type'] as String?,
      inspectionType: json['inspection_type'] as String?,
      title: json['title'] as String? ?? '',
      vehicle: json['vehicle'] as String? ?? '',
      appointmentDate: json['appointment_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      durationLabel: json['duration_label'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      dropAddressText: json['drop_address_text'] as String?,
      amount: json['amount'] as String? ?? '0',
      isPaid: json['is_paid'] as bool? ?? false,
      status: json['status'] as String? ?? 'new',
      assigneeName: json['assignee_name'] as String?,
      needsAssignee: json['needs_assignee'] as bool? ?? false,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
    );
  }

  /// Convert to ServiceRequest domain entity.
  ServiceRequest toDomain() {
    final kind = requestType == 'driver' ? SrKind.driver : SrKind.inspection;

    // Parse vehicle string - usually format is "Make Model (year, condition)"
    final vehicleParts = vehicle.split(' ');
    final make = vehicleParts.isNotEmpty ? vehicleParts.first : 'Unknown';
    final model = vehicleParts.length > 1
        ? vehicleParts.sublist(1).join(' ')
        : 'Unknown';

    return ServiceRequest(
      id: id.toString(),
      kind: kind,
      status: serviceRequestStatusFromKey(status),
      customer: SrCustomer(
        name: customerName,
        phone: customerPhone,
      ),
      vehicle: SrVehicle(
        make: make,
        model: model,
        type: 'Vehicle',
        plate: 'Unknown',
      ),
      when: '$appointmentDate $startTime',
      duration: durationLabel,
      location: addressText,
      createdAt: appointmentDate,
      otp: '',
      note: '',
      timeline: const [],
      // `needs_assignee` is the authoritative flag from the API; a request can
      // be assigned even when the display name is momentarily empty.
      assigneeId: needsAssignee ? null : (assigneeName ?? 'assigned'),
      fee: _parseFee(amount),
    );
  }

  /// Parse fee amount from string.
  static int? _parseFee(String amountStr) {
    try {
      return int.parse(amountStr.replaceAll(',', ''));
    } catch (e) {
      try {
        return double.parse(amountStr.replaceAll(',', '')).toInt();
      } catch (e) {
        return null;
      }
    }
  }
}
