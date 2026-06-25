import '../../../../../app/config/constants.dart';
import '../../../domain/entities/team_member.dart';

/// Static fallback data for the Team feature.
///
/// Drivers and inspectors now come from the §8 Team API; only the founders
/// (not an API concept here) remain local, backing the assignee resolver.
class DriversLocalDs {
  const DriversLocalDs();

  /// Returns the two founders (Anand, Vishnu) as [TeamMember].
  Future<List<TeamMember>> fetchFounders() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _founders;
  }

  // DRIVERS from data.jsx (founders)
  static const List<TeamMember> _founders = [
    TeamMember(
      id: 'd1',
      name: 'Anand',
      role: 'founder',
      phone: '+91 98470 22119',
      active: true,
    ),
    TeamMember(
      id: 'd2',
      name: 'Vishnu',
      role: 'co-founder',
      phone: '+91 90745 88210',
      active: true,
    ),
  ];
}
