import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_options.dart';
import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../data_sources/settlements_api.dart';
import '../data_sources/shop_hours_api.dart';
import '../data_sources/shop_services_api.dart';
import '../data_sources/shops_api.dart';
import '../models/shop_detail_response_model.dart';
import '../models/shop_hours_models.dart';
import '../models/shop_service_response_model.dart';

/// Concrete shop repository using API exclusively.
/// No fallback to mock data - all errors propagate to UI.
class ShopsRepositoryImpl implements ShopsRepository {
  ShopsRepositoryImpl({
    ShopsApi? api,
    ShopServicesApi? servicesApi,
    SettlementsApi? settlementsApi,
    ShopHoursApi? hoursApi,
  })  : _api = api ?? ShopsApi(),
        _servicesApi = servicesApi ?? ShopServicesApi(),
        _settlementsApi = settlementsApi ?? SettlementsApi(),
        _hoursApi = hoursApi ?? ShopHoursApi();

  final ShopsApi _api;
  final ShopServicesApi _servicesApi;
  final SettlementsApi _settlementsApi;
  final ShopHoursApi _hoursApi;

  static const List<String> _weekdayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Future<ShopsPage> fetchShops({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? vehicleType,
    double? minRating,
    String? sort,
  }) async {
    try {
      final response = await _api.getShops(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        vehicleType: vehicleType,
        minRating: minRating,
        sort: sort,
      );

      return ShopsPage(
        items: response.results.map((r) => r.toDomain()).toList(),
        total: response.count,
        hasNextPage: response.hasNextPage,
        nextPageNumber: response.getNextPage(),
      );
    } catch (e) {
      // Propagate the error - don't fallback to mock data
      rethrow;
    }
  }

  @override
  Future<Shop> fetchShopDetail(String shopId) async {
    try {
      final response = await _api.getShopDetail(shopId);
      return response.toDomain();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR parsing shop detail: $e');
      debugPrint('StackTrace: $stackTrace');
      // Propagate the error - don't fallback to mock data
      rethrow;
    }
  }

  @override
  Future<Shop> createShop({
    required String name,
    required String address,
    required String pincode,
    required String city,
    required String state,
    required String phone,
    required String ownerName,
    required String ownerPhone,
    double? latitude,
    double? longitude,
    int? dailyBookingCap,
    List<String>? supportedVehicleTypes,
    required String commissionType,
    String? commissionPercentage,
    String? commissionAmount,
    String? commissionFloor,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
    String? gstin,
    String? pan,
  }) async {
    try {
      final request = ShopCreateRequest(
        name: name,
        address: address,
        pincode: pincode,
        city: city,
        state: state,
        phone: phone,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        latitude: latitude,
        longitude: longitude,
        dailyBookingCap: dailyBookingCap,
        supportedVehicleTypes: supportedVehicleTypes ?? [],
        commissionType: commissionType,
        commissionPercentage: commissionPercentage,
        commissionAmount: commissionAmount,
        commissionFloor: commissionFloor,
        bankAccountName: bankAccountName,
        bankAccountNumber: bankAccountNumber,
        bankIfsc: bankIfsc,
        upiId: upiId,
        gstin: gstin,
        pan: pan,
      );
      final response = await _api.createShop(request);
      return response.toDomain();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR creating shop: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Shop> updateShop(
    String shopId, {
    String? name,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? phone,
    String? ownerName,
    String? ownerPhone,
    double? latitude,
    double? longitude,
    int? dailyBookingCap,
    List<String>? supportedVehicleTypes,
    String? commissionType,
    String? commissionPercentage,
    String? commissionAmount,
    String? commissionFloor,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
    String? gstin,
    String? pan,
    bool? useSlotLevelCapacity,
  }) async {
    try {
      final request = ShopUpdateRequest(
        name: name,
        address: address,
        pincode: pincode,
        city: city,
        state: state,
        phone: phone,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        latitude: latitude,
        longitude: longitude,
        dailyBookingCap: dailyBookingCap,
        supportedVehicleTypes: supportedVehicleTypes,
        commissionType: commissionType,
        commissionPercentage: commissionPercentage,
        commissionAmount: commissionAmount,
        commissionFloor: commissionFloor,
        bankAccountName: bankAccountName,
        bankAccountNumber: bankAccountNumber,
        bankIfsc: bankIfsc,
        upiId: upiId,
        gstin: gstin,
        pan: pan,
        useSlotLevelCapacity: useSlotLevelCapacity,
      );
      final response = await _api.updateShop(shopId, request);
      return response.toDomain();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating shop: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Shop> uploadShopPhoto(
    String shopId, {
    required String slot,
    String? filePath,
    List<int>? bytes,
  }) async {
    final response = await _api.uploadShopPhoto(
      shopId,
      slot,
      filePath: filePath,
      bytes: bytes,
    );
    return response.toDomain();
  }

  @override
  Future<List<WeeklyDay>> fetchWeeklySchedule(String shopId) async {
    final results = await Future.wait([
      _hoursApi.getSlots(),
      _hoursApi.getWeeklyBusinesses(shopId),
      _hoursApi.getSlotBreaks(shopId),
    ]);
    final slots = results[0] as List<SlotModel>;
    final rows = results[1] as List<WeeklyBusinessModel>;
    final breaks = results[2] as List<SlotBreakModel>;

    final hourById = {for (final s in slots) s.id: s.hour};
    final rowByWeekday = {for (final r in rows) r.weekday: r};
    final breaksByWeekday = <int, List<int>>{};
    for (final b in breaks) {
      final hour = hourById[b.slotId];
      if (hour == null) continue;
      (breaksByWeekday[b.weekday] ??= []).add(hour);
    }

    return List.generate(7, (weekday) {
      final row = rowByWeekday[weekday];
      final closed = row == null;
      return WeeklyDay(
        day: _weekdayLabels[weekday],
        weekday: weekday,
        closed: closed,
        open: closed ? 9 : (hourById[row.openingSlot] ?? 9),
        close: closed ? 20 : (hourById[row.closingSlot] ?? 20),
        offSlots: closed
            ? const <int>[]
            : ((breaksByWeekday[weekday] ?? const <int>[]).toSet().toList()
              ..sort()),
      );
    });
  }

  @override
  Future<void> saveWeeklySchedule(String shopId, List<WeeklyDay> days) async {
    final results = await Future.wait([
      _hoursApi.getSlots(),
      _hoursApi.getWeeklyBusinesses(shopId),
    ]);
    final slots = results[0] as List<SlotModel>;
    final rows = results[1] as List<WeeklyBusinessModel>;

    final onTheHourSlotId = {
      for (final s in slots)
        if (s.minute == 0) s.hour: s.id,
    };
    final slotIdByHourMinute = {
      for (final s in slots) '${s.hour}:${s.minute}': s.id,
    };
    final rowByWeekday = {for (final r in rows) r.weekday: r};

    await Future.wait(days.map((day) async {
      final existing = rowByWeekday[day.weekday];

      if (day.closed) {
        if (existing != null) {
          await _hoursApi.deleteWeeklyBusiness(existing.id);
        }
        return;
      }

      final openId = onTheHourSlotId[day.open];
      final closeId = onTheHourSlotId[day.close];
      if (openId == null || closeId == null) {
        throw Exception(
          'Hour ${day.open}–${day.close} has no matching slot on the server grid.',
        );
      }

      if (existing == null) {
        await _hoursApi.createWeeklyBusiness(
          shopId: shopId,
          weekday: day.weekday,
          openingSlotId: openId,
          closingSlotId: closeId,
        );
      } else if (existing.openingSlot != openId ||
          existing.closingSlot != closeId) {
        await _hoursApi.updateWeeklyBusiness(
          id: existing.id,
          openingSlotId: openId,
          closingSlotId: closeId,
        );
      }

      final breakSlotIds = day.offSlots
          .expand((h) => [
                slotIdByHourMinute['$h:0'],
                slotIdByHourMinute['$h:30'],
              ])
          .whereType<int>()
          .toList();
      await _hoursApi.setDayBreaks(
        shopId: shopId,
        weekday: day.weekday,
        slotIds: breakSlotIds,
      );
    }));
  }

  @override
  Future<List<Holiday>> fetchShopHolidays(String shopId) async {
    final holidays = await _hoursApi.getHolidays(shopId);
    return holidays
        .map((h) => Holiday(
              id: h.id.toString(),
              date: h.date,
              label: h.label,
              shopIds: h.shopIds.map((id) => id.toString()).toList(),
            ))
        .toList();
  }

  @override
  Future<Holiday> createHoliday({
    required String date,
    required String label,
    required List<String> shopIds,
  }) async {
    final holiday = await _hoursApi.createHoliday(
      date: date,
      label: label,
      shopIds: shopIds.map(int.parse).toList(),
    );
    return Holiday(
      id: holiday.id.toString(),
      date: holiday.date,
      label: holiday.label,
      shopIds: holiday.shopIds.map((id) => id.toString()).toList(),
    );
  }

  @override
  Future<void> deleteHoliday(String holidayId) =>
      _hoursApi.deleteHoliday(int.parse(holidayId));

  @override
  Future<List<ShopService>> fetchShopServices(String shopId) async {
    final response = await _servicesApi.getServices(shopId);
    return response.results.map((r) => r.toDomain()).toList();
  }

  @override
  Future<ShopService> createService(
    String shopId,
    String name,
    List<String> inclusions,
    bool uniformPricing,
    bool active,
    int? price,
    int? durationInSlots,
    List<({String type, int price, int minutes, bool active})>? variants,
  ) async {
    final request = ShopServiceCreateRequest(
      shop: int.tryParse(shopId),
      name: name,
      inclusions: inclusions,
      uniformPricing: uniformPricing,
      active: active,
      price: uniformPricing ? price : null,
      durationInSlots: uniformPricing ? durationInSlots : null,
      variants: !uniformPricing && variants != null
          ? variants
              .map((v) => ServiceVariantCreateRequest(
                    vehicleType: vehicleTypeSlug(v.type),
                    price: v.price,
                    durationInSlots: v.minutes ~/ 30,
                    active: v.active,
                  ))
              .toList()
          : null,
    );
    final response = await _servicesApi.createService(request);
    return response.toDomain();
  }

  @override
  Future<ShopService> updateService(
    int serviceId,
    String name,
    List<String> inclusions,
    bool uniformPricing,
    bool active,
    int? price,
    int? durationInSlots,
    List<({String type, int price, int minutes, bool active})>? variants,
  ) async {
    final request = ShopServiceCreateRequest(
      name: name,
      inclusions: inclusions,
      uniformPricing: uniformPricing,
      active: active,
      price: uniformPricing ? price : null,
      durationInSlots: uniformPricing ? durationInSlots : null,
      variants: !uniformPricing && variants != null
          ? variants
              .map((v) => ServiceVariantCreateRequest(
                    vehicleType: vehicleTypeSlug(v.type),
                    price: v.price,
                    durationInSlots: v.minutes ~/ 30,
                    active: v.active,
                  ))
              .toList()
          : null,
    );
    final response = await _servicesApi.updateService(serviceId, request);
    return response.toDomain();
  }

  @override
  Future<ShopService> toggleService(int serviceId, bool active) async {
    final response = await _servicesApi.toggleService(serviceId, active);
    return response.toDomain();
  }

  @override
  Future<({int copied, int skipped})> copyServices(
    int sourceShopId,
    int targetShopId,
  ) async {
    final response = await _servicesApi.copyServices(sourceShopId, targetShopId);
    return (
      copied: response['copied'] as int? ?? 0,
      skipped: response['skipped'] as int? ?? 0,
    );
  }

  @override
  Future<({int servicesUpdated, int variantsUpdated})> applyPriceChange(
    String shopId,
    double percent,
  ) async {
    final response = await _servicesApi.applyPriceChange(
      int.parse(shopId),
      percent,
    );
    return (
      servicesUpdated: response['services_updated'] as int? ?? 0,
      variantsUpdated: response['variants_updated'] as int? ?? 0,
    );
  }

  @override
  Future<SettlementPending> fetchPendingSettlements(String shopId) async {
    final response = await _settlementsApi.getPendingSettlements(shopId);
    return SettlementPending(
      shopId: response.shopId,
      count: response.count,
      netPayable: double.tryParse(response.netPayable) ?? 0.0,
      pendingTotal: double.tryParse(response.pendingTotal) ?? 0.0,
      lastSettled: response.lastSettled != null ? DateTime.parse(response.lastSettled!) : null,
      lifetimePaid: double.tryParse(response.lifetimePaid) ?? 0.0,
      items: response.items
          .map((item) => SettlementItemData(
                bookingId: item.bookingId,
                reference: item.reference,
                appointmentDate: item.appointmentDate,
                gross: double.tryParse(item.gross) ?? 0.0,
                commission: double.tryParse(item.commission) ?? 0.0,
                net: double.tryParse(item.net) ?? 0.0,
              ))
          .toList(),
    );
  }

  @override
  Future<SettlementPayout> createPayout(
    String shopId, {
    String? utr,
    String? notes,
  }) async {
    final response = await _settlementsApi.createPayout(shopId, utr: utr, notes: notes);
    return SettlementPayout(
      id: response.id,
      shop: response.shop,
      grossAmount: double.tryParse(response.grossAmount) ?? 0.0,
      commissionAmount: double.tryParse(response.commissionAmount) ?? 0.0,
      totalAmount: double.tryParse(response.totalAmount) ?? 0.0,
      bookingCount: response.bookingCount,
      status: response.status,
      utr: response.utr,
      notes: response.notes,
      periodStart: response.periodStart,
      periodEnd: response.periodEnd,
      createdBy: response.createdBy,
      createdByName: response.createdByName,
      createdAt: DateTime.parse(response.createdAt),
      items: response.items
          .map((item) => PayoutItemData(
                id: item.id,
                booking: item.booking,
                reference: item.reference,
                appointmentDate: item.appointmentDate,
                gross: double.tryParse(item.gross) ?? 0.0,
                commission: double.tryParse(item.commission) ?? 0.0,
                net: double.tryParse(item.net) ?? 0.0,
              ))
          .toList(),
    );
  }

  @override
  Future<SettlementHistory> fetchPayoutHistory(String shopId) async {
    final response = await _settlementsApi.getPayoutHistory(shopId);
    return SettlementHistory(
      count: response.count,
      payouts: response.results
          .map((payout) => SettlementPayout(
                id: payout.id,
                shop: payout.shop,
                grossAmount: double.tryParse(payout.grossAmount) ?? 0.0,
                commissionAmount: double.tryParse(payout.commissionAmount) ?? 0.0,
                totalAmount: double.tryParse(payout.totalAmount) ?? 0.0,
                bookingCount: payout.bookingCount,
                status: payout.status,
                utr: payout.utr,
                notes: payout.notes,
                periodStart: payout.periodStart,
                periodEnd: payout.periodEnd,
                createdBy: payout.createdBy,
                createdByName: payout.createdByName,
                createdAt: DateTime.parse(payout.createdAt),
                items: payout.items
                    .map((item) => PayoutItemData(
                          id: item.id,
                          booking: item.booking,
                          reference: item.reference,
                          appointmentDate: item.appointmentDate,
                          gross: double.tryParse(item.gross) ?? 0.0,
                          commission: double.tryParse(item.commission) ?? 0.0,
                          net: double.tryParse(item.net) ?? 0.0,
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  @override
  Future<SettlementsOverview> fetchSettlementsOverview() async {
    final response = await _settlementsApi.getSettlementsOverview();
    return SettlementsOverview(
      count: response.count,
      shops: response.items
          .map((item) => SettlementOverviewShop(
                shopId: item.shopId,
                name: item.name,
                pendingTotal: double.tryParse(item.pendingTotal) ?? 0.0,
                bookingCount: item.bookingCount,
                period: item.period != null
                    ? DateRange(start: item.period!.start, end: item.period!.end)
                    : null,
                lastPaid: item.lastPaid != null
                    ? LastPaid(
                        date: DateTime.parse(item.lastPaid!.date),
                        amount: double.tryParse(item.lastPaid!.amount) ?? 0.0,
                      )
                    : null,
              ))
          .toList(),
    );
  }
}
