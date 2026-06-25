import '../entities/field_driver.dart';
import '../entities/team_member.dart';

/// Contract for the Team feature (drivers & inspectors).
abstract class DriversRepository {
  // ── Drivers ────────────────────────────────────────────────────────────────

  /// List drivers, optionally filtered by status (`active|invited|suspended`).
  Future<List<FieldDriver>> fetchFieldDrivers({String? status});

  /// Driver detail (active_job / this_week / joined populated).
  Future<FieldDriver?> getDriverDetail(String id);

  /// Hire a driver. Returns the created driver. Throws on 409 (phone exists).
  Future<FieldDriver> hireDriver({
    required String fullName,
    required String phone,
    String? email,
    String? subRole,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  });

  /// Partial update of a driver (and linked user). Returns the updated driver.
  Future<FieldDriver> updateDriver(
    String id, {
    String? fullName,
    String? email,
    String? status,
    String? subRole,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
  });

  Future<void> deleteDriver(String id);

  // ── Inspectors ───────────────────────────────────────────────────────────────

  /// The inspectors (as lightweight [TeamMember]s for the list-only tab).
  Future<List<TeamMember>> fetchInspectors({String? status});

  Future<FieldDriver> hireInspector({
    required String fullName,
    required String phone,
    String? email,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  });

  Future<FieldDriver> updateInspector(
    String id, {
    String? fullName,
    String? email,
    String? status,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
  });

  Future<void> deleteInspector(String id);

  // ── Documents (driver or inspector) ───────────────────────────────────────────

  Future<void> uploadDocument(
    String id, {
    required bool isInspector,
    required String filePath,
    required String kind,
    String side,
    String? name,
  });

  Future<void> patchDocument(
    String id,
    String docId, {
    required bool isInspector,
    bool? frontVerified,
    bool? backVerified,
    bool? verified,
    String? name,
  });

  Future<void> deleteDocument(
    String id,
    String docId, {
    required bool isInspector,
  });

  // ── Founders (still local — not part of §8) ───────────────────────────────────

  /// The founders/operators. Retained for the assignee resolver; static data.
  Future<List<TeamMember>> fetchFounders();
}
