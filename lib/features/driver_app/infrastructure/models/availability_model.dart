import '../../domain/entities/availability.dart';

class AvailabilityModel extends Availability {
  AvailabilityModel({
    required super.status,
    required super.online,
    required super.onJob,
    required super.role,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      status: json['status'] ?? 'inactive',
      online: json['online'] ?? false,
      onJob: json['on_job'] ?? false,
      role: json['role'] ?? 'driver',
    );
  }

  Availability toEntity() => Availability(
    status: status,
    online: online,
    onJob: onJob,
    role: role,
  );
}
