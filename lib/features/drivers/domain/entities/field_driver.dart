import '../../../../core/status/badge_tone.dart';

/// State of a hired field driver / inspector.
///
/// [online] and [offline] are the two ends of the availability toggle the worker
/// controls from their own app — the API spells them `active` / `inactive`, but
/// they mean online / offline and are labelled that way here. [invited] and
/// [suspended] are onboarding states an admin sets; they are not positions on
/// the availability toggle.
enum DriverStatus { online, offline, invited, suspended }

/// Display label and tone for a [DriverStatus].
extension DriverStatusX on DriverStatus {
  String get label => switch (this) {
        DriverStatus.online => 'Online',
        DriverStatus.offline => 'Offline',
        DriverStatus.invited => 'Invited',
        DriverStatus.suspended => 'Suspended',
      };

  BadgeTone get tone => switch (this) {
        DriverStatus.online => BadgeTone.green,
        DriverStatus.offline => BadgeTone.grey,
        DriverStatus.invited => BadgeTone.amber,
        DriverStatus.suspended => BadgeTone.red,
      };
}

/// A driving licence on a field-driver profile.
class DriverLicense {
  const DriverLicense({
    required this.number,
    required this.expiry,
    required this.verified,
  });

  final String number;
  final String expiry;
  final bool verified;
}

/// A jobs/earnings stat pair (today or this week).
class DriverPeriodStat {
  const DriverPeriodStat({required this.jobs, required this.earnings});

  final int jobs;
  final int earnings;
}

/// An uploaded document with optional front/back sides.
///
/// `front`/`back` are the per-side "present" flags the UI toggles render.
/// The API-backed fields (`kind`, file URLs, per-side verified) are optional
/// so local/mock construction stays valid.
class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.type,
    required this.front,
    required this.back,
    this.kind,
    this.name,
    this.frontFileUrl,
    this.backFileUrl,
    this.frontVerified = false,
    this.backVerified = false,
    this.localFrontPath,
    this.localBackPath,
  });

  final String id;
  final String type;
  final bool front;
  final bool back;

  /// Canonical kind: `license` | `aadhaar` | `police_verification` | `other`.
  final String? kind;
  final String? name;
  final String? frontFileUrl;
  final String? backFileUrl;
  final bool frontVerified;
  final bool backVerified;

  /// Files picked on the Hire form, before the worker exists and can own an
  /// upload. They are sent as soon as the hire call returns an id; documents
  /// that already live on the server leave these null.
  final String? localFrontPath;
  final String? localBackPath;

  /// Sides still waiting to be uploaded, as `(side, path)` pairs.
  List<(String, String)> get pendingUploads => [
        if (localFrontPath != null && localFrontPath!.isNotEmpty)
          ('front', localFrontPath!),
        if (localBackPath != null && localBackPath!.isNotEmpty)
          ('back', localBackPath!),
      ];
}

/// Live location of a driver who is currently on a job.
class LiveLocation {
  const LiveLocation({
    required this.label,
    required this.moving,
    required this.lastUpdate,
  });

  final String label;
  final bool moving;
  final String lastUpdate;
}

/// The active job a field driver is on right now (drives the live card).
class DriverCurrentJob {
  const DriverCurrentJob({
    required this.bookingId,
    required this.reference,
    required this.kind,
    required this.type,
    required this.customer,
    required this.stage,
    required this.location,
  });

  /// Raw job kind from the API — `carwash`, `driver_hire` or `inspection`.
  ///
  /// Decides which resource [bookingId] belongs to: carwash ids live under
  /// `/booking/v1/bookings/`, the other two under
  /// `/booking/v1/driver-inspection-requests/`. [type] is the display label
  /// and must not be used for this.
  final String kind;

  /// Numeric booking id, for routing to the booking detail screen. Empty when
  /// the API sent no `booking_id` — callers must check before navigating.
  ///
  /// Kept apart from [reference]: these were one field, so a job with a
  /// reference routed to `/bookings/DT-0005-9E`, which parses to no int and
  /// resolved to nothing.
  final String bookingId;

  /// Human-facing booking reference (e.g. `DT-0005-9E`), for display only.
  final String reference;
  final String type;
  final String customer;
  final String stage;
  final LiveLocation location;
}

/// A hired field driver / inspector with a full profile.
class FieldDriver {
  const FieldDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.role,
    required this.joined,
    required this.license,
    required this.jobsDone,
    required this.vehicleClasses,
    required this.today,
    required this.week,
    required this.documents,
    this.subRole,
    this.documentsCount,
    this.onJobFlag = false,
    this.rating,
    this.currentJob,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final DriverStatus status;

  /// Human role label (e.g. "Wash + hire driver" / "Inspector").
  final String role;

  /// Canonical sub-role: `wash` | `wash_hire` | `hire` (drivers only, else null).
  final String? subRole;
  final String joined;
  final DriverLicense license;
  final double? rating;
  final int jobsDone;
  final List<String> vehicleClasses;
  final DriverPeriodStat today;
  final DriverPeriodStat week;
  final List<DriverDocument> documents;
  final int? documentsCount;

  /// API `on_job` flag (the list endpoint sets this without a [currentJob]).
  final bool onJobFlag;
  final DriverCurrentJob? currentJob;

  bool get onJob => currentJob != null || onJobFlag;
}
