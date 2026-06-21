/// Detail response models for driver/inspection requests

class DriverInspectionDetailResponse {
  final int id;
  final String reference;
  final String requestType; // 'driver' or 'inspection'
  final String status;
  final String title;
  final String? customerPhone;
  final String? carLabel;
  final String? vehicleText;
  final String appointmentDate;
  final String startTime;
  final String durationLabel;
  final String addressText;
  final double? latitude;
  final double? longitude;
  final String? quotedFee;
  final String? estimatedFee;
  final String? customerNote;
  final bool isPaid;
  final WorkerModel? worker;
  final List<TimelineEntryModel> timeline;
  final String? startOtp;
  final String? endOtp;

  DriverInspectionDetailResponse({
    required this.id,
    required this.reference,
    required this.requestType,
    required this.status,
    required this.title,
    this.customerPhone,
    this.carLabel,
    this.vehicleText,
    required this.appointmentDate,
    required this.startTime,
    required this.durationLabel,
    required this.addressText,
    this.latitude,
    this.longitude,
    this.quotedFee,
    this.estimatedFee,
    this.customerNote,
    required this.isPaid,
    this.worker,
    required this.timeline,
    this.startOtp,
    this.endOtp,
  });

  factory DriverInspectionDetailResponse.fromJson(Map<String, dynamic> json) {
    return DriverInspectionDetailResponse(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      requestType: json['request_type'] as String? ?? 'driver',
      status: json['status'] as String? ?? 'new',
      title: json['title'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      carLabel: json['car_label'] as String?,
      vehicleText: json['vehicle_text'] as String?,
      appointmentDate: json['appointment_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      durationLabel: json['duration_label'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      quotedFee: json['quoted_fee'] as String?,
      estimatedFee: json['estimated_fee'] as String?,
      customerNote: json['customer_note'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      worker: json['worker'] != null
          ? WorkerModel.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      timeline: ((json['timeline'] as List<dynamic>?) ?? [])
          .map((item) =>
              TimelineEntryModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      startOtp: json['start_otp'] as String?,
      endOtp: json['end_otp'] as String?,
    );
  }
}

class WorkerModel {
  final int id;
  final String name;
  final String title;
  final String role;
  final String phone;
  final String? maskedPhone;
  final double? rating;

  WorkerModel({
    required this.id,
    required this.name,
    required this.title,
    required this.role,
    required this.phone,
    this.maskedPhone,
    this.rating,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      maskedPhone: json['masked_phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class TimelineEntryModel {
  final int id;
  final String status;
  final String actorName;
  final String source; // 'system', 'Customer app', etc
  final String? note;
  final double? latitude;
  final double? longitude;
  final String? locationText;
  final String createdAt;

  TimelineEntryModel({
    required this.id,
    required this.status,
    required this.actorName,
    required this.source,
    this.note,
    this.latitude,
    this.longitude,
    this.locationText,
    required this.createdAt,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      actorName: json['actor_name'] as String? ?? '',
      source: json['source'] as String? ?? 'system',
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationText: json['location_text'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

/// Response for assignable workers list
class AssignableWorkersResponse {
  final int count;
  final List<AssignableWorkerModel> items;

  AssignableWorkersResponse({
    required this.count,
    required this.items,
  });

  factory AssignableWorkersResponse.fromJson(Map<String, dynamic> json) {
    return AssignableWorkersResponse(
      count: json['count'] as int? ?? 0,
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((item) =>
              AssignableWorkerModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AssignableWorkerModel {
  final int id;
  final String name;
  final String role;
  final String title;
  final String phone;
  final String? maskedPhone;
  final double? rating;
  final bool available;

  AssignableWorkerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.title,
    required this.phone,
    this.maskedPhone,
    this.rating,
    required this.available,
  });

  factory AssignableWorkerModel.fromJson(Map<String, dynamic> json) {
    return AssignableWorkerModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      title: json['title'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      maskedPhone: json['masked_phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      available: json['available'] as bool? ?? false,
    );
  }
}

/// Generic action response
class ActionResponse {
  final String message;
  final Map<String, dynamic>? data;

  ActionResponse({
    required this.message,
    this.data,
  });

  factory ActionResponse.fromJson(Map<String, dynamic> json) {
    return ActionResponse(
      message: json['message'] as String? ?? 'Success',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
