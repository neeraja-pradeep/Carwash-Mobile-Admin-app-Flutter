import '../../../../core/status/badge_tone.dart';

/// Onboarding state of a hired field driver / inspector.
enum DriverStatus { active, invited, suspended }

/// Display label and tone for a [DriverStatus].
extension DriverStatusX on DriverStatus {
  String get label => switch (this) {
        DriverStatus.active => 'Active',
        DriverStatus.invited => 'Invited',
        DriverStatus.suspended => 'Suspended',
      };

  BadgeTone get tone => switch (this) {
        DriverStatus.active => BadgeTone.green,
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
class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.type,
    required this.front,
    required this.back,
  });

  final String id;
  final String type;
  final bool front;
  final bool back;
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
    required this.type,
    required this.customer,
    required this.stage,
    required this.location,
  });

  final String bookingId;
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
    this.rating,
    this.currentJob,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final DriverStatus status;
  final String role;
  final String joined;
  final DriverLicense license;
  final double? rating;
  final int jobsDone;
  final List<String> vehicleClasses;
  final DriverPeriodStat today;
  final DriverPeriodStat week;
  final List<DriverDocument> documents;
  final DriverCurrentJob? currentJob;

  bool get onJob => currentJob != null;
}
