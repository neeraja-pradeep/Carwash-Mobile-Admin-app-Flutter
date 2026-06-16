/// Driver hiring & inspection operations snapshot (from `data.jsx` HIRING_SNAPSHOT).
class HiringSnapshot {
  const HiringSnapshot({
    required this.driversOnline,
    required this.driversTotal,
    required this.onJobNow,
    required this.hireRequestsToday,
    required this.hireOpen,
    required this.inspectionsToday,
    required this.inspectOpen,
  });

  /// Number of drivers currently online.
  final int driversOnline;

  /// Total registered drivers.
  final int driversTotal;

  /// Drivers currently on an active job.
  final int onJobNow;

  /// Hire requests received today.
  final int hireRequestsToday;

  /// Hire requests that still need an assignee.
  final int hireOpen;

  /// Vehicle inspections scheduled today.
  final int inspectionsToday;

  /// Inspections not yet assigned.
  final int inspectOpen;
}
