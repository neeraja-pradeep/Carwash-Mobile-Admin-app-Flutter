import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';

/// API response from GET /api/booking/v1/admin/dashboard/
class DashboardResponseModel {
  final String? adminName;
  final int overdue;
  final BookingsTodayModel bookingsToday;
  final int activeNow;
  final PendingRefundsModel pendingRefunds;
  final UnassignedModel unassigned;
  final int unassignedAlertMinutes;
  final DriverInspectorModel driverInspector;

  DashboardResponseModel({
    required this.adminName,
    required this.overdue,
    required this.bookingsToday,
    required this.activeNow,
    required this.pendingRefunds,
    required this.unassigned,
    required this.unassignedAlertMinutes,
    required this.driverInspector,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      adminName: json['admin_name'] as String?,
      overdue: json['overdue'] as int? ?? 0,
      bookingsToday: BookingsTodayModel.fromJson(
        json['bookings_today'] as Map<String, dynamic>? ?? {},
      ),
      activeNow: json['active_now'] as int? ?? 0,
      pendingRefunds: PendingRefundsModel.fromJson(
        json['pending_refunds'] as Map<String, dynamic>? ?? {},
      ),
      unassigned: UnassignedModel.fromJson(
        json['unassigned'] as Map<String, dynamic>? ?? {},
      ),
      unassignedAlertMinutes: json['unassigned_alert_minutes'] as int? ?? 15,
      driverInspector: DriverInspectorModel.fromJson(
        json['driver_inspector'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  DashboardSnapshot toDomain() {
    return DashboardSnapshot(
      bookingsToday: bookingsToday.total,
      waiting: bookingsToday.waiting,
      inProgress: bookingsToday.active,
      doneToday: bookingsToday.done,
      activeNow: activeNow,
      overdue: overdue,
      pendingRefunds: pendingRefunds.count,
      pendingRefundAmt: _parseAmount(pendingRefunds.amount),
      adminName: adminName,
      unassignedCount: unassigned.count,
      unassignedOldestMinutes: unassigned.oldestMinutes,
      unassignedAlertMinutes: unassignedAlertMinutes,
    );
  }

  static num _parseAmount(String? amountStr) {
    if (amountStr == null || amountStr.isEmpty) return 0;
    try {
      return num.parse(amountStr);
    } catch (e) {
      return 0;
    }
  }
}

class BookingsTodayModel {
  final int total;
  final int waiting;
  final int active;
  final int done;

  BookingsTodayModel({
    required this.total,
    required this.waiting,
    required this.active,
    required this.done,
  });

  factory BookingsTodayModel.fromJson(Map<String, dynamic> json) {
    return BookingsTodayModel(
      total: json['total'] as int? ?? 0,
      waiting: json['waiting'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
    );
  }
}

class PendingRefundsModel {
  final int count;
  final String amount;

  PendingRefundsModel({
    required this.count,
    required this.amount,
  });

  factory PendingRefundsModel.fromJson(Map<String, dynamic> json) {
    return PendingRefundsModel(
      count: json['count'] as int? ?? 0,
      amount: json['amount'] as String? ?? '0.00',
    );
  }
}

class UnassignedModel {
  final int count;
  final int? oldestMinutes;

  UnassignedModel({
    required this.count,
    this.oldestMinutes,
  });

  factory UnassignedModel.fromJson(Map<String, dynamic> json) {
    return UnassignedModel(
      count: json['count'] as int? ?? 0,
      oldestMinutes: json['oldest_minutes'] as int?,
    );
  }
}

class DriverInspectorModel {
  final DriversOnlineModel driversOnline;
  final HireRequestsModel hireRequests;
  final InspectionsModel inspections;
  final int onJobNow;

  DriverInspectorModel({
    required this.driversOnline,
    required this.hireRequests,
    required this.inspections,
    required this.onJobNow,
  });

  factory DriverInspectorModel.fromJson(Map<String, dynamic> json) {
    return DriverInspectorModel(
      driversOnline: DriversOnlineModel.fromJson(
        json['drivers_online'] as Map<String, dynamic>? ?? {},
      ),
      hireRequests: HireRequestsModel.fromJson(
        json['hire_requests'] as Map<String, dynamic>? ?? {},
      ),
      inspections: InspectionsModel.fromJson(
        json['inspections'] as Map<String, dynamic>? ?? {},
      ),
      onJobNow: json['on_job_now'] as int? ?? 0,
    );
  }

  HiringSnapshot toHiringSnapshot() {
    return HiringSnapshot(
      driversOnline: driversOnline.online,
      driversTotal: driversOnline.total,
      onJobNow: onJobNow,
      hireRequestsToday: hireRequests.count,
      hireOpen: hireRequests.needsAssignee,
      inspectionsToday: inspections.count,
      inspectOpen: inspections.open,
    );
  }
}

class DriversOnlineModel {
  final int online;
  final int total;
  final int onJob;

  DriversOnlineModel({
    required this.online,
    required this.total,
    required this.onJob,
  });

  factory DriversOnlineModel.fromJson(Map<String, dynamic> json) {
    return DriversOnlineModel(
      online: json['online'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      onJob: json['on_job'] as int? ?? 0,
    );
  }
}

class HireRequestsModel {
  final int count;
  final int needsAssignee;

  HireRequestsModel({
    required this.count,
    required this.needsAssignee,
  });

  factory HireRequestsModel.fromJson(Map<String, dynamic> json) {
    return HireRequestsModel(
      count: json['count'] as int? ?? 0,
      needsAssignee: json['needs_assignee'] as int? ?? 0,
    );
  }
}

class InspectionsModel {
  final int count;
  final int open;

  InspectionsModel({
    required this.count,
    required this.open,
  });

  factory InspectionsModel.fromJson(Map<String, dynamic> json) {
    return InspectionsModel(
      count: json['count'] as int? ?? 0,
      open: json['open'] as int? ?? 0,
    );
  }
}
