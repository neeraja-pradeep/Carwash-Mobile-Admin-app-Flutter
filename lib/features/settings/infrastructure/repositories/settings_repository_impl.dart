import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/settings_api.dart';
import '../models/hiring_rates_model.dart';
import '../models/notification_preference_model.dart';
import '../models/org_info_model.dart';
import '../models/serviceability_area_model.dart';

/// Remote-backed settings repository. Aggregates the four endpoints into one
/// [AppSettings] read and patches each independently on write.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({SettingsApi? api}) : _api = api ?? SettingsApi();

  final SettingsApi _api;

  // Platform slot grid is fixed at 30-minute blocks (no endpoint, see §13).
  static const int _slotIntervalMinutes = 30;

  // Refund tiers have no backing config — refunds are set manually (§13.4).
  static const RefundTiers _refundTiers = RefundTiers(
    full: 'Before assignment',
    partial: 'After assignment, before pickup',
    none: 'After pickup',
  );

  static const String _appVersion = 'v0.1.0 (build 47)';

  @override
  Future<AppSettings> fetchSettings() async {
    try {
      final results = await Future.wait([
        _api.getOrgInfo(),
        _api.getHiringRates(),
        _api.getServiceAreas(),
        _api.getNotificationPreferences(),
      ]);

      final org = results[0] as OrgInfoModel;
      final rates = results[1] as HiringRatesModel;
      final areas = results[2] as List<ServiceabilityAreaModel>;
      final notif = results[3] as NotificationPreferenceModel;

      final entities = areas.map((a) => a.toEntity()).toList();
      final carwash =
          entities.where((a) => a.types.contains('carwash')).toList();
      final hire = entities
          .where((a) =>
              a.types.contains('driver') || a.types.contains('inspector'))
          .toList();

      return AppSettings(
        business: org.toBusinessInfo(),
        refundTiers: _refundTiers,
        slotInterval: _slotIntervalMinutes,
        defaultCommission: org.toDefaultCommission(),
        serviceAreas: ServiceAreas(carwash: carwash, hire: hire),
        rates: rates.toEntity(),
        notifications: notif.toEntity(),
        appVersion: _appVersion,
      );
    } catch (e) {
      debugPrint('❌ ERROR fetching settings: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateOrgInfo({
    String? legalName,
    String? gstin,
    String? supportPhone,
    String? supportEmail,
    int? defaultCommissionPercent,
  }) async {
    try {
      await _api.patchOrgInfo(buildOrgInfoPayload(
        legalName: legalName,
        gstin: gstin,
        supportPhone: supportPhone,
        supportEmail: supportEmail,
        defaultCommissionPercent: defaultCommissionPercent,
      ));
    } catch (e) {
      debugPrint('❌ ERROR updating org info: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateHiringRates({
    int? driverFirstHour,
    int? driverPerExtraHour,
    int? driverMinHours,
    int? driverNightSurcharge,
    int? driverTravelBasePerKm,
    int? inspectorBaseFee,
    int? inspectorWrittenReport,
  }) async {
    try {
      await _api.patchHiringRates(buildHiringRatesPayload(
        driverFirstHour: driverFirstHour,
        driverPerExtraHour: driverPerExtraHour,
        driverMinHours: driverMinHours,
        driverNightSurcharge: driverNightSurcharge,
        driverTravelBasePerKm: driverTravelBasePerKm,
        inspectorBaseFee: inspectorBaseFee,
        inspectorWrittenReport: inspectorWrittenReport,
      ));
    } catch (e) {
      debugPrint('❌ ERROR updating hiring rates: $e');
      rethrow;
    }
  }

  @override
  Future<ServiceArea> createArea({
    required String name,
    required String pincode,
    required int radiusKm,
    required double latitude,
    required double longitude,
    required List<String> types,
  }) async {
    try {
      final model = await _api.createServiceArea(buildServiceAreaPayload(
        name: name,
        pincode: pincode,
        radiusKm: radiusKm,
        latitude: latitude,
        longitude: longitude,
        types: types,
      ));
      return model.toEntity();
    } catch (e) {
      debugPrint('❌ ERROR creating service area: $e');
      rethrow;
    }
  }

  @override
  Future<ServiceArea> updateArea(
    int id, {
    String? name,
    String? pincode,
    int? radiusKm,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final model = await _api.updateServiceArea(
        id,
        buildServiceAreaPayload(
          name: name,
          pincode: pincode,
          radiusKm: radiusKm,
          latitude: latitude,
          longitude: longitude,
        ),
      );
      return model.toEntity();
    } catch (e) {
      debugPrint('❌ ERROR updating service area: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteArea(int id) async {
    try {
      await _api.deleteServiceArea(id);
    } catch (e) {
      debugPrint('❌ ERROR deleting service area: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNotifications({
    bool? newBooking,
    bool? refundRequest,
    bool? lowRating,
  }) async {
    try {
      await _api.patchNotificationPreferences(buildNotificationPayload(
        newBooking: newBooking,
        refundRequests: refundRequest,
        lowRatings: lowRating,
      ));
    } catch (e) {
      debugPrint('❌ ERROR updating notifications: $e');
      rethrow;
    }
  }
}
