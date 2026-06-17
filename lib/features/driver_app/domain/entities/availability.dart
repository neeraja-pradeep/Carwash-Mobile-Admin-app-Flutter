class Availability {
  final String status;
  final bool online;
  final bool onJob;
  final String role;

  Availability({
    required this.status,
    required this.online,
    required this.onJob,
    required this.role,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      status: json['status'] ?? 'inactive',
      online: json['online'] ?? false,
      onJob: json['on_job'] ?? false,
      role: json['role'] ?? 'driver',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'online': online,
    'on_job': onJob,
    'role': role,
  };
}
