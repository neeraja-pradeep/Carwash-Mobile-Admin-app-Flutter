import 'field_driver.dart';

/// A simple team member — a founder/operator or an inspector. Used wherever a
/// booking/request assignee just needs name + phone + role.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;

  /// e.g. `founder`, `co-founder`, `inspector`.
  final String role;
  final String phone;

  /// The worker's real state. Carried whole rather than as an is-active flag:
  /// collapsing it to a bool loses the difference between someone who toggled
  /// themselves offline and someone an admin suspended.
  final DriverStatus status;

  /// True only when the member is on the books *and* online.
  bool get active => status == DriverStatus.online;
}
