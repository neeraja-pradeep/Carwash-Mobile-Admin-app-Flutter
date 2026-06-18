import '../../../../core/status/badge_tone.dart';

enum WorkerStatus { active, inactive, assigned }

extension WorkerStatusX on WorkerStatus {
  String get label => switch (this) {
        WorkerStatus.active => 'Active',
        WorkerStatus.inactive => 'Inactive',
        WorkerStatus.assigned => 'Assigned',
      };

  BadgeTone get tone => switch (this) {
        WorkerStatus.active => BadgeTone.green,
        WorkerStatus.inactive => BadgeTone.grey,
        WorkerStatus.assigned => BadgeTone.amber,
      };
}

class WorkerProfile {
  const WorkerProfile({
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
  final WorkerStatus status;
  final bool online;
  final double? rating;
  final String? licenseNumber;
  final int jobsDone;
}
