/// Immutable domain entities for the Settings feature.
///
/// Mirrors the `SETTINGS` object in `data.jsx` (lines 671–691).
/// All fields are final; no JSON serialisation yet (static local data only).

class BusinessInfo {
  const BusinessInfo({
    required this.name,
    required this.city,
    required this.gstin,
    required this.support,
    required this.email,
  });

  final String name;
  final String city;
  final String gstin;
  final String support;
  final String email;
}

class ServiceArea {
  const ServiceArea({
    required this.id,
    required this.name,
    required this.pincode,
    required this.radiusKm,
  });

  final String id;
  final String name;
  final String pincode;
  final int radiusKm;
}

class ServiceAreas {
  const ServiceAreas({
    required this.carwash,
    required this.hire,
  });

  final List<ServiceArea> carwash;
  final List<ServiceArea> hire;
}

class DriverRates {
  const DriverRates({
    required this.firstHour,
    required this.hourly,
    required this.fullDay,
    required this.perKm,
    required this.minHours,
    required this.nightSurcharge,
    required this.travelDay,
    required this.travelNight,
  });

  final int firstHour;
  final int hourly;
  final int fullDay;
  final int perKm;
  final int minHours;
  final int nightSurcharge;
  final int travelDay;
  final int travelNight;
}

class InspectorRates {
  const InspectorRates({
    required this.baseFee,
    required this.hourly,
    required this.perKm,
    required this.reportFee,
    required this.premiumSuv,
    required this.travelWorkday,
    required this.travelHoliday,
  });

  final int baseFee;
  final int hourly;
  final int perKm;
  final int reportFee;
  final int premiumSuv;
  final int travelWorkday;
  final int travelHoliday;
}

class HiringRates {
  const HiringRates({
    required this.driver,
    required this.inspector,
  });

  final DriverRates driver;
  final InspectorRates inspector;
}

class RefundTiers {
  const RefundTiers({
    required this.full,
    required this.partial,
    required this.none,
  });

  final String full;
  final String partial;
  final String none;
}

class DefaultCommission {
  const DefaultCommission({
    required this.mode,
    required this.pct,
  });

  final String mode;
  final int pct;
}

class NotificationToggles {
  const NotificationToggles({
    required this.newBooking,
    required this.refundRequest,
    required this.lowRating,
    required this.dailySummary,
    required this.payoutDue,
  });

  final bool newBooking;
  final bool refundRequest;
  final bool lowRating;
  final bool dailySummary;
  final bool payoutDue;

  NotificationToggles copyWith({
    bool? newBooking,
    bool? refundRequest,
    bool? lowRating,
    bool? dailySummary,
    bool? payoutDue,
  }) {
    return NotificationToggles(
      newBooking: newBooking ?? this.newBooking,
      refundRequest: refundRequest ?? this.refundRequest,
      lowRating: lowRating ?? this.lowRating,
      dailySummary: dailySummary ?? this.dailySummary,
      payoutDue: payoutDue ?? this.payoutDue,
    );
  }
}

/// Root settings aggregate — everything on the Settings screen.
class AppSettings {
  const AppSettings({
    required this.business,
    required this.refundTiers,
    required this.slotInterval,
    required this.defaultCommission,
    required this.serviceAreas,
    required this.rates,
    required this.notifications,
    required this.appVersion,
  });

  final BusinessInfo business;
  final RefundTiers refundTiers;
  final int slotInterval;
  final DefaultCommission defaultCommission;
  final ServiceAreas serviceAreas;
  final HiringRates rates;
  final NotificationToggles notifications;
  final String appVersion;
}
