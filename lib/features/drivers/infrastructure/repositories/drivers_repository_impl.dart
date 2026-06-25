import 'package:flutter/foundation.dart';

import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../data_sources/drivers_api.dart';
import '../data_sources/local/drivers_local_ds.dart';

/// Fulfils [DriversRepository] from the §8 Team API (remote-first; rethrows).
///
/// Founders remain local (not an API concept here); the local DS is kept for
/// that single fallback.
class DriversRepositoryImpl implements DriversRepository {
  DriversRepositoryImpl({DriversApi? api, DriversLocalDs? local})
      : _api = api ?? DriversApi(),
        _local = local ?? const DriversLocalDs();

  final DriversApi _api;
  final DriversLocalDs _local;

  // ── Drivers ────────────────────────────────────────────────────────────────

  @override
  Future<List<FieldDriver>> fetchFieldDrivers({String? status}) async {
    try {
      final res = await _api.listDrivers(status: status);
      return res.results.map((m) => m.toEntity()).toList();
    } catch (e, st) {
      debugPrint('❌ ERROR fetching drivers: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<FieldDriver?> getDriverDetail(String id) async {
    try {
      final m = await _api.getDriverDetail(id);
      return m.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR fetching driver detail: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<FieldDriver> hireDriver({
    required String fullName,
    required String phone,
    String? email,
    String? subRole,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) async {
    final m = await _api.hireDriver(
      fullName: fullName,
      phone: phone,
      email: email,
      subRole: subRole,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
    );
    return m.toEntity();
  }

  @override
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
  }) async {
    final m = await _api.updateDriver(
      id,
      fullName: fullName,
      email: email,
      status: status,
      subRole: subRole,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
      phone: phone,
    );
    return m.toEntity();
  }

  @override
  Future<void> deleteDriver(String id) => _api.deleteDriver(id);

  // ── Inspectors ───────────────────────────────────────────────────────────────

  @override
  Future<List<TeamMember>> fetchInspectors({String? status}) async {
    try {
      final res = await _api.listInspectors(status: status);
      return res.results.map((m) => m.toTeamMember()).toList();
    } catch (e, st) {
      debugPrint('❌ ERROR fetching inspectors: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<FieldDriver> hireInspector({
    required String fullName,
    required String phone,
    String? email,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) async {
    final m = await _api.hireInspector(
      fullName: fullName,
      phone: phone,
      email: email,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
    );
    return m.toEntity();
  }

  @override
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
  }) async {
    final m = await _api.updateInspector(
      id,
      fullName: fullName,
      email: email,
      status: status,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
      phone: phone,
    );
    return m.toEntity();
  }

  @override
  Future<void> deleteInspector(String id) => _api.deleteInspector(id);

  // ── Documents ─────────────────────────────────────────────────────────────────

  @override
  Future<void> uploadDocument(
    String id, {
    required bool isInspector,
    required String filePath,
    required String kind,
    String side = 'front',
    String? name,
  }) async {
    await _api.uploadDocument(
      id,
      isInspector: isInspector,
      filePath: filePath,
      kind: kind,
      side: side,
      name: name,
    );
  }

  @override
  Future<void> patchDocument(
    String id,
    String docId, {
    required bool isInspector,
    bool? frontVerified,
    bool? backVerified,
    bool? verified,
    String? name,
  }) async {
    await _api.patchDocument(
      id,
      docId,
      isInspector: isInspector,
      frontVerified: frontVerified,
      backVerified: backVerified,
      verified: verified,
      name: name,
    );
  }

  @override
  Future<void> deleteDocument(
    String id,
    String docId, {
    required bool isInspector,
  }) =>
      _api.deleteDocument(id, docId, isInspector: isInspector);

  // ── Founders (local fallback) ────────────────────────────────────────────────

  @override
  Future<List<TeamMember>> fetchFounders() => _local.fetchFounders();
}
