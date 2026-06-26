import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import 'json_helpers.dart';

/// `HiringRates` singleton from GET /api/booking/v1/hiring-rates/.
///
/// The backend stores money values as decimal strings. The screen only exposes
/// a subset; travel allowance maps to the tiered model's per-km fields (see
/// §13.2): driver "Travel · base per km" → [driverTravelBasePerKm], inspector
/// travel → [inspectorPerKm].
class HiringRatesModel {
  final int driverFirstHour;
  final int driverPerExtraHour;
  final int driverFullDay;
  final int driverPerKm;
  final int driverMinHours;
  final int driverNightSurcharge;
  final int driverTravelBasePerKm;
  final int inspectorBaseFee;
  final int inspectorPerKm;
  final int inspectorWrittenReport;
  final int inspectorPremiumSuvAddon;

  HiringRatesModel({
    required this.driverFirstHour,
    required this.driverPerExtraHour,
    required this.driverFullDay,
    required this.driverPerKm,
    required this.driverMinHours,
    required this.driverNightSurcharge,
    required this.driverTravelBasePerKm,
    required this.inspectorBaseFee,
    required this.inspectorPerKm,
    required this.inspectorWrittenReport,
    required this.inspectorPremiumSuvAddon,
  });

  factory HiringRatesModel.fromJson(Map<String, dynamic> json) {
    try {
      return HiringRatesModel(
        driverFirstHour: asInt(json['driver_first_hour']),
        driverPerExtraHour: asInt(json['driver_per_extra_hour']),
        driverFullDay: asInt(json['driver_full_day']),
        driverPerKm: asInt(json['driver_per_km']),
        driverMinHours: asInt(json['driver_min_hours']),
        driverNightSurcharge: asInt(json['driver_night_surcharge']),
        driverTravelBasePerKm: asInt(json['driver_travel_base_per_km']),
        inspectorBaseFee: asInt(json['inspector_base_fee']),
        inspectorPerKm: asInt(json['inspector_per_km']),
        inspectorWrittenReport: asInt(json['inspector_written_report']),
        inspectorPremiumSuvAddon: asInt(json['inspector_premium_suv_addon']),
      );
    } catch (e) {
      debugPrint('Error parsing HiringRatesModel: $e');
      rethrow;
    }
  }

  HiringRates toEntity() {
    return HiringRates(
      driver: DriverRates(
        firstHour: driverFirstHour,
        hourly: driverPerExtraHour,
        fullDay: driverFullDay,
        perKm: driverPerKm,
        minHours: driverMinHours,
        nightSurcharge: driverNightSurcharge,
        travelDay: driverTravelBasePerKm,
        travelNight: driverNightSurcharge,
      ),
      inspector: InspectorRates(
        baseFee: inspectorBaseFee,
        hourly: 0,
        perKm: inspectorPerKm,
        reportFee: inspectorWrittenReport,
        premiumSuv: inspectorPremiumSuvAddon,
        travelWorkday: inspectorPerKm,
        travelHoliday: 0,
      ),
    );
  }
}

/// Builds the PATCH /hiring-rates/ payload. Only the screen-editable fields are
/// included; values go as decimal strings to match the serializer.
Map<String, dynamic> buildHiringRatesPayload({
  int? driverFirstHour,
  int? driverPerExtraHour,
  int? driverMinHours,
  int? driverNightSurcharge,
  int? driverTravelBasePerKm,
  int? inspectorBaseFee,
  int? inspectorWrittenReport,
}) {
  return {
    if (driverFirstHour != null)
      'driver_first_hour': driverFirstHour.toString(),
    if (driverPerExtraHour != null)
      'driver_per_extra_hour': driverPerExtraHour.toString(),
    if (driverMinHours != null) 'driver_min_hours': driverMinHours,
    if (driverNightSurcharge != null)
      'driver_night_surcharge': driverNightSurcharge.toString(),
    if (driverTravelBasePerKm != null)
      'driver_travel_base_per_km': driverTravelBasePerKm.toString(),
    if (inspectorBaseFee != null)
      'inspector_base_fee': inspectorBaseFee.toString(),
    if (inspectorWrittenReport != null)
      'inspector_written_report': inspectorWrittenReport.toString(),
  };
}
