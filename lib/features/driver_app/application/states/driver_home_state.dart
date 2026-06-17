import '../../domain/entities/availability.dart';
import '../../domain/entities/stats.dart';
import '../../domain/entities/job_feed.dart';

abstract class DriverHomeState {
  const DriverHomeState();
}

class DriverHomeInitial extends DriverHomeState {
  const DriverHomeInitial();
}

class DriverHomeLoading extends DriverHomeState {
  const DriverHomeLoading();
}

class DriverHomeSuccess extends DriverHomeState {
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

  const DriverHomeError({required this.message, this.code});
}

class AvailabilityUpdating extends DriverHomeState {
  const AvailabilityUpdating();
}

class AvailabilityUpdated extends DriverHomeState {
  final Availability availability;

  const AvailabilityUpdated({required this.availability});
}
