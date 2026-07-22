import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/repositories/settings_repository_impl.dart';

/// The settings repository (domain contract → infrastructure impl).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
);

/// All settings (read). Aggregates the four backing endpoints. autoDispose so
/// re-entering the screen refetches; mutations invalidate it via [SettingsActions].
final appSettingsProvider = FutureProvider.autoDispose<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).fetchSettings(),
);

/// Mutation actions — each calls the repository then invalidates
/// [appSettingsProvider] so the screen re-reads the fresh state.
final settingsActionsProvider = Provider<SettingsActions>(
  (ref) => SettingsActions(ref),
);

class SettingsActions {
  SettingsActions(this._ref);

  final Ref _ref;

  SettingsRepository get _repo => _ref.read(settingsRepositoryProvider);

  void _refresh() => _ref.invalidate(appSettingsProvider);

  Future<void> updateOrgInfo({
    String? legalName,
    String? gstin,
    String? supportPhone,
    String? supportEmail,
    int? defaultCommissionPercent,
  }) async {
    await _repo.updateOrgInfo(
      legalName: legalName,
      gstin: gstin,
      supportPhone: supportPhone,
      supportEmail: supportEmail,
      defaultCommissionPercent: defaultCommissionPercent,
    );
    _refresh();
  }

  Future<void> updateHiringRates({
    int? driverFirstHour,
    int? driverPerExtraHour,
    int? driverMinHours,
    int? driverNightSurcharge,
    int? driverTravelBasePerKm,
    int? inspectorBaseFee,
    int? inspectorWrittenReport,
  }) async {
    await _repo.updateHiringRates(
      driverFirstHour: driverFirstHour,
      driverPerExtraHour: driverPerExtraHour,
      driverMinHours: driverMinHours,
      driverNightSurcharge: driverNightSurcharge,
      driverTravelBasePerKm: driverTravelBasePerKm,
      inspectorBaseFee: inspectorBaseFee,
      inspectorWrittenReport: inspectorWrittenReport,
    );
    _refresh();
  }

  Future<void> createArea({
    required String name,
    required String pincode,
    required int radiusKm,
    required double latitude,
    required double longitude,
    required List<String> types,
  }) async {
    await _repo.createArea(
      name: name,
      pincode: pincode,
      radiusKm: radiusKm,
      latitude: latitude,
      longitude: longitude,
      types: types,
    );
    _refresh();
  }

  Future<void> updateArea(
    int id, {
    String? name,
    String? pincode,
    int? radiusKm,
    double? latitude,
    double? longitude,
  }) async {
    await _repo.updateArea(
      id,
      name: name,
      pincode: pincode,
      radiusKm: radiusKm,
      latitude: latitude,
      longitude: longitude,
    );
    _refresh();
  }

  Future<void> deleteArea(int id) async {
    await _repo.deleteArea(id);
    _refresh();
  }

  Future<void> updateNotifications({
    bool? newBooking,
    bool? refundRequest,
    bool? lowRating,
  }) async {
    await _repo.updateNotifications(
      newBooking: newBooking,
      refundRequest: refundRequest,
      lowRating: lowRating,
    );
    _refresh();
  }
}
