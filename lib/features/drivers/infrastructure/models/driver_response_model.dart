import 'package:flutter/foundation.dart';

import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';

/// Models for the Team (Drivers & Inspectors) API — §8 of docs/api_admin.md.
///
/// Covers the list/detail worker envelope, the nested `user` block, and the
/// shared `WorkerDocument`. Drivers and inspectors share the same shape; the
/// only differences are `sub_role` (drivers only) and the status field name
/// (`driver_status` vs `inspector_status`) — both handled here.

// ── User sub-object ───────────────────────────────────────────────────────────

class WorkerUserModel {
  WorkerUserModel({
    required this.id,
    required this.username,
    required this.phone,
    required this.email,
  });

  final int id;
  final String username;
  final String phone;
  final String email;

  factory WorkerUserModel.fromJson(Map<String, dynamic> json) {
    return WorkerUserModel(
      id: _toInt(json['id']),
      username: _toString(json['username']) ?? '',
      phone: _toString(json['phone']) ?? '',
      email: _toString(json['email']) ?? '',
    );
  }
}

// ── WorkerDocument ────────────────────────────────────────────────────────────

class DriverDocumentModel {
  DriverDocumentModel({
    required this.id,
    required this.kind,
    required this.kindLabel,
    required this.name,
    required this.frontFileUrl,
    required this.frontVerified,
    required this.backFileUrl,
    required this.backVerified,
    required this.fileUrl,
    required this.verified,
    required this.uploadedAt,
    required this.updatedAt,
  });

  final int id;
  final String kind;
  final String kindLabel;
  final String? name;
  final String? frontFileUrl;
  final bool frontVerified;
  final String? backFileUrl;
  final bool backVerified;
  final String? fileUrl;
  final bool verified;
  final String? uploadedAt;
  final String? updatedAt;

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    try {
      return DriverDocumentModel(
        id: _toInt(json['id']),
        kind: _toString(json['kind']) ?? 'other',
        kindLabel: _toString(json['kind_label']) ?? '',
        name: _toString(json['name']),
        frontFileUrl: _toString(json['front_file_url']),
        frontVerified: _toBool(json['front_verified']),
        backFileUrl: _toString(json['back_file_url']),
        backVerified: _toBool(json['back_verified']),
        fileUrl: _toString(json['file_url']),
        verified: _toBool(json['verified']),
        uploadedAt: _toString(json['uploaded_at']),
        updatedAt: _toString(json['updated_at']),
      );
    } catch (e) {
      debugPrint('Error parsing DriverDocumentModel: $e');
      rethrow;
    }
  }

  DriverDocument toEntity() {
    // Display label: explicit `name` wins, else the human kind label, else kind.
    final label = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : (kindLabel.isNotEmpty ? kindLabel : kind);
    // A side is "present" when it has a file OR is verified.
    final hasFront =
        frontVerified || (frontFileUrl != null && frontFileUrl!.isNotEmpty);
    final hasBack =
        backVerified || (backFileUrl != null && backFileUrl!.isNotEmpty);
    return DriverDocument(
      id: id.toString(),
      type: label,
      front: hasFront,
      back: hasBack,
      kind: kind,
      name: name,
      frontFileUrl: frontFileUrl,
      backFileUrl: backFileUrl,
      frontVerified: frontVerified,
      backVerified: backVerified,
    );
  }
}

// ── Active job (detail only) ──────────────────────────────────────────────────

class ActiveJobModel {
  ActiveJobModel({
    required this.kind,
    required this.bookingType,
    required this.bookingId,
    required this.reference,
    required this.stage,
    required this.stageCode,
    required this.reason,
    required this.location,
  });

  final String kind;
  final String? bookingType;
  final int? bookingId;
  final String? reference;
  final String? stage;
  final String? stageCode;
  final String? reason;
  final ActiveJobLocationModel? location;

  factory ActiveJobModel.fromJson(Map<String, dynamic> json) {
    return ActiveJobModel(
      kind: _toString(json['kind']) ?? '',
      bookingType: _toString(json['booking_type']),
      bookingId: json['booking_id'] == null ? null : _toInt(json['booking_id']),
      reference: _toString(json['reference']),
      stage: _toString(json['stage']),
      stageCode: _toString(json['stage_code']),
      reason: _toString(json['reason']),
      location: json['location'] is Map<String, dynamic>
          ? ActiveJobLocationModel.fromJson(
              json['location'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  DriverCurrentJob toEntity(String workerName) {
    final loc = location;
    return DriverCurrentJob(
      bookingId: reference ?? (bookingId?.toString() ?? ''),
      type: _kindLabel(kind),
      customer: reason ?? workerName,
      stage: stage ?? (stageCode ?? ''),
      location: LiveLocation(
        label: loc?.text ?? 'Location unavailable',
        // No live GPS — position is the last status event (never "moving").
        moving: false,
        lastUpdate: loc?.updatedAt ?? '—',
      ),
    );
  }

  static String _kindLabel(String kind) => switch (kind) {
        'driver_hire' => 'Driver hire',
        'inspection' => 'Inspection',
        'carwash' => 'Carwash',
        _ => kind,
      };
}

class ActiveJobLocationModel {
  ActiveJobLocationModel({
    required this.text,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    required this.source,
  });

  final String? text;
  final double? latitude;
  final double? longitude;
  final String? updatedAt;
  final String? source;

  factory ActiveJobLocationModel.fromJson(Map<String, dynamic> json) {
    return ActiveJobLocationModel(
      text: _toString(json['text']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      updatedAt: _toString(json['updated_at']),
      source: _toString(json['source']),
    );
  }
}

// ── Worker (driver / inspector) — list + detail envelope ──────────────────────

class FieldDriverModel {
  FieldDriverModel({
    required this.id,
    required this.user,
    required this.name,
    required this.profilePicture,
    required this.status,
    required this.subRole,
    required this.roleLabel,
    required this.jobsCount,
    required this.onJob,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.licenseVerified,
    required this.licenseStatus,
    required this.vehicleClasses,
    required this.rating,
    required this.documents,
    required this.documentsCount,
    // detail-only
    required this.activeJob,
    required this.thisWeek,
    required this.jobsDone,
    required this.joined,
  });

  final int id;
  final WorkerUserModel? user;
  final String name;
  final String? profilePicture;

  /// `driver_status` (drivers) or `inspector_status` (inspectors).
  final String status;
  final String? subRole;
  final String roleLabel;
  final int jobsCount;
  final bool onJob;
  final String licenseNumber;
  final String licenseExpiry;
  final bool licenseVerified;
  final String licenseStatus;
  final List<String> vehicleClasses;
  final double? rating;
  final List<DriverDocumentModel> documents;
  final int documentsCount;

  // Detail-only blocks (null/absent on list).
  final ActiveJobModel? activeJob;
  final DriverPeriodStatModel? thisWeek;
  final int jobsDone;
  final String? joined;

  factory FieldDriverModel.fromJson(Map<String, dynamic> json) {
    try {
      final docsList = (json['documents'] as List?)
              ?.map((e) =>
                  DriverDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <DriverDocumentModel>[];

      // status field differs between drivers / inspectors.
      final status = _toString(json['driver_status']) ??
          _toString(json['inspector_status']) ??
          'active';

      return FieldDriverModel(
        id: _toInt(json['id']),
        user: json['user'] is Map<String, dynamic>
            ? WorkerUserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        name: _toString(json['name']) ?? '',
        profilePicture: _toString(json['profile_picture']),
        status: status,
        subRole: _toString(json['sub_role']),
        roleLabel: _toString(json['role_label']) ?? '',
        jobsCount: _toInt(json['jobs_count']),
        onJob: _toBool(json['on_job']),
        licenseNumber: _toString(json['license_number']) ?? '',
        licenseExpiry: _toString(json['license_expiry']) ?? '',
        licenseVerified: _toBool(json['license_verified']),
        licenseStatus: _toString(json['license_status']) ?? 'pending',
        vehicleClasses: (json['vehicle_classes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        rating: _toDouble(json['rating']),
        documents: docsList,
        documentsCount:
            json['documents_count'] == null ? docsList.length : _toInt(json['documents_count']),
        activeJob: json['active_job'] is Map<String, dynamic>
            ? ActiveJobModel.fromJson(json['active_job'] as Map<String, dynamic>)
            : null,
        thisWeek: json['this_week'] is Map<String, dynamic>
            ? DriverPeriodStatModel.fromJson(
                json['this_week'] as Map<String, dynamic>,
              )
            : null,
        jobsDone: json['jobs_done'] == null
            ? _toInt(json['jobs_count'])
            : _toInt(json['jobs_done']),
        joined: _toString(json['joined']),
      );
    } catch (e) {
      debugPrint('Error parsing FieldDriverModel: $e');
      rethrow;
    }
  }

  DriverStatus get _statusEnum => switch (status) {
        'active' => DriverStatus.active,
        'invited' => DriverStatus.invited,
        'suspended' => DriverStatus.suspended,
        // assigned/inactive aren't surfaced as chips — fold into active.
        _ => DriverStatus.active,
      };

  /// Maps to the rich [FieldDriver] entity used across the Drivers screens.
  FieldDriver toEntity() {
    final week = thisWeek;
    return FieldDriver(
      id: id.toString(),
      name: name,
      phone: user?.phone ?? '',
      email: user?.email ?? '',
      status: _statusEnum,
      role: roleLabel.isNotEmpty ? roleLabel : 'Driver',
      subRole: subRole,
      joined: joined ?? '',
      license: DriverLicense(
        number: licenseNumber,
        expiry: licenseExpiry,
        verified: licenseVerified,
      ),
      rating: rating,
      jobsDone: jobsDone,
      vehicleClasses:
          vehicleClasses.map(vehicleClassLabel).toList(growable: false),
      today: const DriverPeriodStat(jobs: 0, earnings: 0),
      week: DriverPeriodStat(
        jobs: week?.jobs ?? 0,
        earnings: week?.earnings ?? 0,
      ),
      documents: documents.map((d) => d.toEntity()).toList(),
      documentsCount: documentsCount,
      onJobFlag: onJob,
      currentJob: activeJob?.toEntity(name),
    );
  }

  /// Maps a worker to the lightweight [TeamMember] used by the Inspectors list
  /// and the assignee-resolver.
  TeamMember toTeamMember() {
    return TeamMember(
      id: id.toString(),
      name: name,
      role: roleLabel.isNotEmpty ? roleLabel : 'Inspector',
      phone: user?.phone ?? '',
      active: status == 'active',
    );
  }
}

class DriverPeriodStatModel {
  DriverPeriodStatModel({required this.jobs, required this.earnings});

  final int jobs;
  final int earnings;

  factory DriverPeriodStatModel.fromJson(Map<String, dynamic> json) {
    return DriverPeriodStatModel(
      jobs: _toInt(json['jobs']),
      // earnings is a decimal string e.g. "4200.00".
      earnings: _toDouble(json['earnings'])?.round() ?? 0,
    );
  }
}

// ── List envelope ─────────────────────────────────────────────────────────────

class DriverListResponse {
  DriverListResponse({required this.results});

  final List<FieldDriverModel> results;

  factory DriverListResponse.fromJson(dynamic data) {
    try {
      // Supports both a bare list and a DRF paginated `{results: [...]}` body.
      final List<dynamic> raw;
      if (data is List) {
        raw = data;
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        raw = data['results'] as List;
      } else {
        raw = const [];
      }
      return DriverListResponse(
        results: raw
            .map((e) => FieldDriverModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      debugPrint('Error parsing DriverListResponse: $e');
      return DriverListResponse(results: const []);
    }
  }
}

// ── Vehicle-class mapping ─────────────────────────────────────────────────────

/// Canonical vehicle types accepted by the API.
const Set<String> kCanonicalVehicleClasses = {
  'hatchback',
  'sedan',
  'suv',
  'convertible',
  'bike',
};

/// Maps a UI vehicle-class chip label to the canonical API enum value.
/// "Compact SUV" / "Premium SUV" / "SUV" all collapse to `suv` (🔴 gap).
String canonicalVehicleClass(String label) {
  final n = label.trim().toLowerCase();
  if (n.contains('suv')) return 'suv';
  if (n.contains('hatch')) return 'hatchback';
  if (n.contains('sedan')) return 'sedan';
  if (n.contains('convert')) return 'convertible';
  if (n.contains('bike') || n.contains('motor')) return 'bike';
  return kCanonicalVehicleClasses.contains(n) ? n : n;
}

/// Maps a list of UI chip labels to a de-duplicated canonical list for the API.
List<String> canonicalVehicleClasses(Iterable<String> labels) {
  final out = <String>[];
  for (final l in labels) {
    final c = canonicalVehicleClass(l);
    if (!out.contains(c)) out.add(c);
  }
  return out;
}

/// Human label for a canonical vehicle class (display in the UI).
String vehicleClassLabel(String canonical) => switch (canonical.toLowerCase()) {
      'hatchback' => 'Hatchback',
      'sedan' => 'Sedan',
      'suv' => 'SUV',
      'convertible' => 'Convertible',
      'bike' => 'Bike',
      _ => canonical,
    };

// ── Sub-role mapping ──────────────────────────────────────────────────────────

/// Maps a `kDriverRoles` UI label to the canonical `sub_role` enum.
/// "Inspector" is not a driver sub-role → null (handled separately by the form).
String? subRoleFromLabel(String label) => switch (label.trim().toLowerCase()) {
      'wash driver' => 'wash',
      'wash + hire driver' => 'wash_hire',
      'hire driver' => 'hire',
      _ => null,
    };

/// Maps a canonical `sub_role` back to its `kDriverRoles` UI label.
String roleLabelFromSubRole(String? subRole) => switch (subRole) {
      'wash' => 'Wash driver',
      'wash_hire' => 'Wash + hire driver',
      'hire' => 'Hire driver',
      _ => 'Wash driver',
    };

/// Maps a UI document-type label (`kDocTypes`) to the canonical document kind.
String docKindFromLabel(String label) {
  final n = label.trim().toLowerCase();
  if (n.contains('licen')) return 'license';
  if (n.contains('aadhaar') || n.contains('aadhar')) return 'aadhaar';
  if (n.contains('police')) return 'police_verification';
  return 'other';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
  return false;
}
