/// Commission model for a third-party shop.
enum CommissionMode { percentage, flat, floor }

/// A shop's negotiated commission and its calculation.
class Commission {
  const Commission({required this.mode, this.pct, this.flat, this.floor});

  final CommissionMode mode;
  final int? pct;
  final int? flat;
  final int? floor;

  /// Human-readable summary, e.g. `15%`, `₹40/booking`, `15% · min ₹30`.
  String get label => switch (mode) {
        CommissionMode.percentage => '$pct%',
        CommissionMode.flat => '₹$flat/booking',
        CommissionMode.floor => '$pct% · min ₹$floor',
      };

  /// Commission amount on a [gross] booking value.
  int amountOn(int gross) => switch (mode) {
        CommissionMode.percentage => ((gross * (pct ?? 0)) / 100).round(),
        CommissionMode.flat => flat ?? 0,
        CommissionMode.floor =>
          (((gross * (pct ?? 0)) / 100).round()).clamp(floor ?? 0, gross),
      };
}

/// Bank / UPI details for manual payouts.
class BankDetails {
  const BankDetails({
    required this.accName,
    required this.accNo,
    required this.ifsc,
    required this.upi,
    required this.gstin,
    required this.pan,
  });

  final String accName;
  final String accNo;
  final String ifsc;
  final String upi;
  final String gstin;
  final String pan;
}

/// A single day's operating hours.
class DayHours {
  const DayHours({
    required this.day,
    required this.open,
    required this.close,
    required this.closed,
  });

  final String day;
  final String open;
  final String close;
  final bool closed;
}

/// A weekly slot-config day (24h ints + break slots turned off).
class WeeklyDay {
  const WeeklyDay({
    required this.day,
    required this.closed,
    required this.open,
    required this.close,
    this.offSlots = const [],
  });

  final String day;
  final bool closed;
  final int open;
  final int close;
  final List<int> offSlots;
}

/// Per-vehicle-type pricing row for a service.
class ServicePricing {
  const ServicePricing({
    required this.type,
    required this.price,
    required this.minutes,
    required this.active,
  });

  final String type;
  final int price;
  final int minutes;
  final bool active;
}

/// A service offered by a shop (flat price or per-vehicle matrix).
class ShopService {
  const ShopService({
    required this.id,
    required this.name,
    required this.description,
    required this.samePrice,
    required this.active,
    this.flatPrice,
    this.flatMinutes,
    this.pricing = const [],
  });

  final String id;
  final String name;
  final String description;
  final bool samePrice;
  final bool active;
  final int? flatPrice;
  final int? flatMinutes;
  final List<ServicePricing> pricing;
}

/// A pending (un-settled) completed booking line for a shop.
class PendingSettlement {
  const PendingSettlement({
    required this.date,
    required this.bookingId,
    required this.gross,
    required this.commission,
    required this.refund,
  });

  final String date;
  final String bookingId;
  final int gross;
  final int commission;
  final int refund;

  int get net => gross - commission - refund;
}

/// A past payout entry in a shop's settlement history.
class SettlementHistoryItem {
  const SettlementHistoryItem({
    required this.period,
    required this.net,
    required this.status,
    required this.utr,
  });

  final String period;
  final int net;
  final String status;
  final String utr;
}

/// A shop's settlement summary.
class Settlement {
  const Settlement({
    required this.lastSettled,
    required this.lifetimePaid,
    required this.pending,
    required this.history,
  });

  final String lastSettled;
  final int lifetimePaid;
  final List<PendingSettlement> pending;
  final List<SettlementHistoryItem> history;
}

/// Who/when meta for onboarding & edits.
class EditMeta {
  const EditMeta({required this.date, required this.by});

  final String date;
  final String by;
}

/// A third-party car-wash shop.
class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.area,
    required this.ownerName,
    required this.ownerPhone,
    required this.shopPhone,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.todayBookings,
    required this.cap,
    required this.avgServiceMin,
    required this.active,
    required this.vehicleTypes,
    required this.commission,
    required this.bank,
    required this.hours,
    required this.photos,
    required this.onboarded,
    required this.lastEdited,
    required this.services,
    required this.settlement,
    required this.weekly,
    required this.slotCapacityEnabled,
    required this.slotCap,
    this.pincode = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  final String id;
  final String name;
  final String area;
  final String ownerName;
  final String ownerPhone;
  final String shopPhone;
  final String address;
  final double rating;
  final int reviews;
  final int todayBookings;
  final int cap;
  final int avgServiceMin;
  final bool active;
  final List<String> vehicleTypes;
  final Commission commission;
  final BankDetails bank;
  final List<DayHours> hours;
  final List<String> photos;
  final EditMeta onboarded;
  final EditMeta lastEdited;
  final List<ShopService> services;
  final Settlement settlement;
  final List<WeeklyDay> weekly;
  final bool slotCapacityEnabled;
  final int slotCap;

  /// Postal code as its own column server-side — it is not always present in
  /// [address], so the edit form can't reliably scrape it back out.
  final String pincode;
  final double latitude;
  final double longitude;

  int get activeServices => services.where((s) => s.active).length;
}
