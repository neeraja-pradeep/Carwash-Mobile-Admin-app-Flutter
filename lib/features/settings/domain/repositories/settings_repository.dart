import '../entities/app_settings.dart';

/// Contract for reading and updating application settings.
///
/// `fetchSettings` aggregates the four backing endpoints (org-info,
/// hiring-rates, serviceability-areas, notification-preferences); the mutation
/// methods patch each one independently.
abstract class SettingsRepository {
  Future<AppSettings> fetchSettings();

  Future<void> updateOrgInfo({
    String? legalName,
    String? gstin,
    String? supportPhone,
    String? supportEmail,
    int? defaultCommissionPercent,
  });

  Future<void> updateHiringRates({
    int? driverFirstHour,
    int? driverPerExtraHour,
    int? driverMinHours,
    int? driverNightSurcharge,
    int? driverTravelBasePerKm,
    int? inspectorBaseFee,
    int? inspectorWrittenReport,
  });

  Future<ServiceArea> createArea({
    required String name,
    required String pincode,
    required int radiusKm,
    required double latitude,
    required double longitude,
    required List<String> types,
  });

  Future<ServiceArea> updateArea(
    int id, {
    String? name,
    String? pincode,
    int? radiusKm,
    double? latitude,
    double? longitude,
  });

  Future<void> deleteArea(int id);

  Future<void> updateNotifications({
    bool? newBooking,
    bool? refundRequest,
    bool? lowRating,
  });
}
