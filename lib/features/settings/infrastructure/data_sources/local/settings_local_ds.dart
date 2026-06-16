import '../../../../../app/config/constants.dart';
import '../../../domain/entities/app_settings.dart';

/// Static sample settings (from `data.jsx` SETTINGS, lines 671–691).
///
/// This is the sole data source in the static prototype. In the API phase a
/// remote source + local cache plug in behind the same repository contract
/// without touching providers or UI.
class SettingsLocalDs {
  const SettingsLocalDs();

  Future<AppSettings> fetchSettings() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _settings;
  }

  static const AppSettings _settings = AppSettings(
    business: BusinessInfo(
      name: 'DriveDeck Carwash',
      city: 'Alappuzha, Kerala',
      gstin: '32ABCFS1234K1Z5',
      support: '+91 98470 22119',
      email: 'ops@drivedeck.in',
    ),
    refundTiers: RefundTiers(
      full: 'Before assignment',
      partial: 'After assignment, before pickup',
      none: 'After pickup',
    ),
    slotInterval: 60,
    defaultCommission: DefaultCommission(mode: 'percentage', pct: 15),
    serviceAreas: ServiceAreas(
      carwash: [
        ServiceArea(id: 'ca1', name: 'Mullackal', pincode: '688011', radiusKm: 5),
        ServiceArea(id: 'ca2', name: 'Thathampally', pincode: '688013', radiusKm: 4),
      ],
      hire: [
        ServiceArea(id: 'h1', name: 'Alappuzha Town', pincode: '688001', radiusKm: 12),
      ],
    ),
    rates: HiringRates(
      driver: DriverRates(
        firstHour: 180,
        hourly: 120,
        fullDay: 1200,
        perKm: 12,
        minHours: 2,
        nightSurcharge: 150,
        travelDay: 80,
        travelNight: 140,
      ),
      inspector: InspectorRates(
        baseFee: 800,
        hourly: 0,
        perKm: 10,
        reportFee: 200,
        premiumSuv: 300,
        travelWorkday: 100,
        travelHoliday: 180,
      ),
    ),
    notifications: NotificationToggles(
      newBooking: true,
      refundRequest: true,
      lowRating: true,
      dailySummary: true,
      payoutDue: false,
    ),
    appVersion: 'v0.1.0 (build 47)',
  );
}
