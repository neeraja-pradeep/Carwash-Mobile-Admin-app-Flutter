import '../../domain/entities/hiring_snapshot.dart';

/// Extracted from DashboardResponseModel.driverInspector
class HiringResponseModel {
  final int driversOnline;
  final int driversTotal;
  final int onJobNow;
  final int hireRequestsToday;
  final int hireOpen;
  final int inspectionsToday;
  final int inspectOpen;

  HiringResponseModel({
    required this.driversOnline,
    required this.driversTotal,
    required this.onJobNow,
    required this.hireRequestsToday,
    required this.hireOpen,
    required this.inspectionsToday,
    required this.inspectOpen,
  });

  HiringSnapshot toDomain() {
    return HiringSnapshot(
      driversOnline: driversOnline,
      driversTotal: driversTotal,
      onJobNow: onJobNow,
      hireRequestsToday: hireRequestsToday,
      hireOpen: hireOpen,
      inspectionsToday: inspectionsToday,
      inspectOpen: inspectOpen,
    );
  }
}
