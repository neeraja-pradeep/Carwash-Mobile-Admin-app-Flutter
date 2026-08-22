import '../../domain/entities/availability.dart';
import '../../domain/entities/stats.dart';
import '../../domain/entities/job_feed.dart';

abstract class DriverHomeState {
  const DriverHomeState();

  /// Last known availability, carried across loading/error so the header keeps
  /// showing the real toggle state.
  ///
  /// `null` means "never fetched" — callers must render that as *unknown*, not
  /// as offline. Reporting a driver offline when we simply failed to load is
  /// what made the admin console and the driver app disagree.
  Availability? get availability => null;
}

class DriverHomeInitial extends DriverHomeState {
  const DriverHomeInitial();
}

class DriverHomeLoading extends DriverHomeState {
  const DriverHomeLoading({this.availability});

  @override
  final Availability? availability;
}

class DriverHomeSuccess extends DriverHomeState {
  @override
  final Availability availability;
  final Stats stats;
  final JobFeed jobFeed;

  const DriverHomeSuccess({
    required this.availability,
    required this.stats,
    required this.jobFeed,
  });
}

class DriverHomeError extends DriverHomeState {
  final String message;
  final String? code;

  /// Availability is kept even on failure — a stats/feed error says nothing
  /// about whether the driver is online.
  @override
  final Availability? availability;

  const DriverHomeError({
    required this.message,
    this.code,
    this.availability,
  });
}

class AvailabilityUpdating extends DriverHomeState {
  const AvailabilityUpdating({this.availability});

  @override
  final Availability? availability;
}

class AvailabilityUpdated extends DriverHomeState {
  @override
  final Availability availability;

  const AvailabilityUpdated({required this.availability});
}
