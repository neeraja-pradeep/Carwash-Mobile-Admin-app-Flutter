import '../../../../core/status/service_request_status.dart';
import '../../../drivers/domain/entities/field_driver.dart' show LiveLocation;

/// The two phone-in service types handled on one screen.
enum SrKind { driver, inspection }

/// Display label for an [SrKind].
extension SrKindX on SrKind {
  String get label => switch (this) {
        SrKind.driver => 'Driver',
        SrKind.inspection => 'Inspection',
      };
}

/// Customer on a service request.
class SrCustomer {
  const SrCustomer({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Vehicle on a service request (plate may read "Pre-purchase").
class SrVehicle {
  const SrVehicle({
    required this.make,
    required this.model,
    required this.type,
    required this.plate,
  });

  final String make;
  final String model;
  final String type;
  final String plate;

  String get title => '$make $model';
}

/// A status transition on a service request, optionally with a captured
/// location (job start/end).
class SrTimelineEntry {
  const SrTimelineEntry({
    required this.status,
    required this.at,
    required this.by,
    this.location,
  });

  final ServiceRequestStatus status;
  final String at;
  final String by;
  final String? location;
}

/// Completion summary for a finished job (deviation + extra charge).
class SrSummary {
  const SrSummary({
    required this.plannedHours,
    required this.actualHours,
    required this.extraKm,
    required this.baseFee,
    required this.extraCharge,
    required this.extraReason,
    required this.total,
    required this.paid,
  });

  final int plannedHours;
  final int actualHours;
  final int extraKm;
  final int baseFee;
  final int extraCharge;
  final String extraReason;
  final int total;
  final bool paid;
}

/// A driver-hire or vehicle-inspection service request.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.customer,
    required this.vehicle,
    required this.when,
    required this.duration,
    required this.location,
    required this.createdAt,
    required this.otp,
    required this.note,
    required this.timeline,
    this.assigneeId,
    this.assigneeName,
    this.fee,
    this.reason,
    this.startLoc,
    this.endLoc,
    this.live,
    this.summary,
  });

  final String id;
  final SrKind kind;
  final ServiceRequestStatus status;
  final SrCustomer customer;
  final SrVehicle vehicle;
  final String when;
  final String duration;
  final String location;
  final String createdAt;
  final String otp;
  final String note;
  final List<SrTimelineEntry> timeline;
  final String? assigneeId;

  /// Display name of the assigned worker, as provided by the list API
  /// (`assignee_name`). Null when the request still needs an assignee.
  final String? assigneeName;
  final int? fee;
  final String? reason;
  final String? startLoc;
  final String? endLoc;
  final LiveLocation? live;
  final SrSummary? summary;
}
