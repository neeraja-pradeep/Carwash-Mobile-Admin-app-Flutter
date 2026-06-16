/// Lifecycle bucket for a job in the scoped Driver app.
enum DriverJobState { active, upcoming, completed }

/// A line in a job's fare breakdown (e.g. extra hour, night allowance).
class FareItem {
  const FareItem({required this.label, required this.amount});

  final String label;
  final int amount;
}

/// The fare summary for a driver job (carwash payout or hire trip total).
class DriverFare {
  const DriverFare({
    required this.base,
    required this.items,
    required this.extra,
    required this.total,
    required this.collect,
    this.plannedHours,
    this.actualHours,
  });

  final int base;
  final List<FareItem> items;
  final int extra;
  final int total;
  final int collect;
  final int? plannedHours;
  final int? actualHours;
}

/// A job assigned to the signed-in driver (Today / Schedule lists).
class DriverJob {
  const DriverJob({
    required this.id,
    required this.type,
    required this.state,
    required this.customer,
    required this.phone,
    required this.vehicle,
    required this.pickup,
    required this.drop,
    required this.shop,
    required this.time,
    required this.payout,
    required this.stage,
    required this.otp,
    required this.fare,
    this.reason,
  });

  final String id;
  final String type;
  final DriverJobState state;
  final String customer;
  final String phone;
  final String vehicle;
  final String pickup;
  final String drop;
  final String shop;
  final String time;
  final int payout;
  final String stage;
  final String otp;
  final DriverFare fare;
  final String? reason;
}
