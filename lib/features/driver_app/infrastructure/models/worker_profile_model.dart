import '../../domain/entities/worker_profile.dart';

class WorkerProfileModel {
  const WorkerProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.profilePicture,
    required this.role,
    required this.roleLabel,
    required this.title,
    required this.status,
    required this.online,
    required this.rating,
    required this.licenseNumber,
    required this.jobsDone,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String profilePicture;
  final String role;
  final String roleLabel;
  final String title;
  final String status;
  final bool online;
  final double? rating;
  final String? licenseNumber;
  final int jobsDone;

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePicture: json['profile_picture'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      online: json['online'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      licenseNumber: json['license_number'] as String?,
      jobsDone: json['jobs_done'] as int? ?? 0,
    );
  }

  WorkerProfile toEntity() {
    return WorkerProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      profilePicture: profilePicture,
      role: role,
      roleLabel: roleLabel,
      title: title,
      status: _parseStatus(status),
      online: online,
      rating: rating,
      licenseNumber: licenseNumber,
      jobsDone: jobsDone,
    );
  }

  static WorkerStatus _parseStatus(String status) {
    return switch (status.toLowerCase()) {
      'active' => WorkerStatus.active,
      'assigned' => WorkerStatus.assigned,
      _ => WorkerStatus.inactive,
    };
  }
}
