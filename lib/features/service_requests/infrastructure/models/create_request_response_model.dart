// Models for customer search and create request APIs

/// Response from customer search API
class CustomerListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<CustomerModel> results;

  CustomerListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => CustomerModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Customer model from list response
class CustomerModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? initials;
  final String? email;

  CustomerModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.initials,
    this.email,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      initials: json['initials'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Response from add new customer API
class CreateCustomerResponse {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? initials;

  CreateCustomerResponse({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.initials,
  });

  factory CreateCustomerResponse.fromJson(Map<String, dynamic> json) {
    return CreateCustomerResponse(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      initials: json['initials'] as String?,
    );
  }
}

/// Response when customer already exists (409 conflict)
class CustomerExistsResponse {
  final String message;
  final int customerId;

  CustomerExistsResponse({
    required this.message,
    required this.customerId,
  });

  factory CustomerExistsResponse.fromJson(Map<String, dynamic> json) {
    return CustomerExistsResponse(
      message: json['phone'] as String? ?? 'Customer already exists',
      customerId: json['customer_id'] as int? ?? 0,
    );
  }
}

/// Response from create request API
class CreateRequestResponse {
  final int id;
  final String reference;
  final String requestType;
  final String status;
  final String title;
  final String? customerPhone;
  final String? carLabel;
  final String vehicleText;
  final String appointmentDate;
  final String startTime;
  final String durationLabel;
  final String addressText;
  final String? quotedFee;
  final String? estimatedFee;
  final String? customerNote;

  CreateRequestResponse({
    required this.id,
    required this.reference,
    required this.requestType,
    required this.status,
    required this.title,
    this.customerPhone,
    this.carLabel,
    required this.vehicleText,
    required this.appointmentDate,
    required this.startTime,
    required this.durationLabel,
    required this.addressText,
    this.quotedFee,
    this.estimatedFee,
    this.customerNote,
  });

  factory CreateRequestResponse.fromJson(Map<String, dynamic> json) {
    return CreateRequestResponse(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      requestType: json['request_type'] as String? ?? 'driver',
      status: json['status'] as String? ?? 'new',
      title: json['title'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      carLabel: json['car_label'] as String?,
      vehicleText: json['vehicle_text'] as String? ?? '',
      appointmentDate: json['appointment_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      durationLabel: json['duration_label'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      quotedFee: json['quoted_fee'] as String?,
      estimatedFee: json['estimated_fee'] as String?,
      customerNote: json['customer_note'] as String?,
    );
  }
}
