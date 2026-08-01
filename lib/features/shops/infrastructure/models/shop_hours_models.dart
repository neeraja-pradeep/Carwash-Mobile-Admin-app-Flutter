/// A single reference slot from `GET /api/shop/v1/slots/` — the fixed,
/// shop-independent 30-minute grid (`id`, `start_time`).
class SlotModel {
  final int id;
  final int hour;
  final int minute;

  SlotModel({required this.id, required this.hour, required this.minute});

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    final startTime = json['start_time'] as String? ?? '00:00:00';
    final parts = startTime.split(':');
    return SlotModel(
      id: json['id'] as int? ?? 0,
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }
}

/// One `(shop, weekday)` row from `shop-weekly-businesses/` — the day's
/// open/close hours, expressed as `Slot` ids.
class WeeklyBusinessModel {
  final int id;
  final int weekday;
  final int openingSlot;
  final int closingSlot;

  WeeklyBusinessModel({
    required this.id,
    required this.weekday,
    required this.openingSlot,
    required this.closingSlot,
  });

  factory WeeklyBusinessModel.fromJson(Map<String, dynamic> json) {
    return WeeklyBusinessModel(
      id: json['id'] as int? ?? 0,
      weekday: json['weekday'] as int? ?? 0,
      openingSlot: json['opening_slot'] as int? ?? 0,
      closingSlot: json['closing_slot'] as int? ?? 0,
    );
  }
}

/// A single recurring weekly break from `shop-slot-breaks/` — one `Slot`
/// turned OFF on one weekday.
class SlotBreakModel {
  final int id;
  final int weekday;
  final int slotId;

  SlotBreakModel({
    required this.id,
    required this.weekday,
    required this.slotId,
  });

  factory SlotBreakModel.fromJson(Map<String, dynamic> json) {
    return SlotBreakModel(
      id: json['id'] as int? ?? 0,
      weekday: json['weekday'] as int? ?? 0,
      slotId: json['slot'] as int? ?? 0,
    );
  }
}

/// A holiday row from `holidays/` — a labeled date that closes one or more
/// shops.
class HolidayApiModel {
  final int id;
  final String date;
  final String label;
  final List<int> shopIds;

  HolidayApiModel({
    required this.id,
    required this.date,
    required this.label,
    required this.shopIds,
  });

  factory HolidayApiModel.fromJson(Map<String, dynamic> json) {
    return HolidayApiModel(
      id: json['id'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      shopIds: ((json['shops'] as List<dynamic>?) ?? [])
          .map((s) => s as int)
          .toList(),
    );
  }
}
