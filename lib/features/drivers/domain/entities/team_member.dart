/// A simple team member — a founder/operator or an inspector. Used wherever a
/// booking/request assignee just needs name + phone + role.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.active,
  });

  final String id;
  final String name;

  /// e.g. `founder`, `co-founder`, `inspector`.
  final String role;
  final String phone;
  final bool active;
}
