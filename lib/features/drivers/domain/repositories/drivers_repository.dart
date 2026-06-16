import '../entities/field_driver.dart';
import '../entities/team_member.dart';

/// Contract for reading driver / inspector / founder data.
/// Pure abstract — no implementation here.
abstract class DriversRepository {
  /// All four hired field drivers (fd1–fd4).
  Future<List<FieldDriver>> fetchFieldDrivers();

  /// The two founders (Anand, Vishnu).
  Future<List<TeamMember>> fetchFounders();

  /// The two inspectors (Ravi Menon, Salim K).
  Future<List<TeamMember>> fetchInspectors();
}
