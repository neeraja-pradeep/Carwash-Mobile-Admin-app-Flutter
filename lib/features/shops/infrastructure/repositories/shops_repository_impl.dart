import 'package:flutter/foundation.dart';

import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../data_sources/local/shops_local_ds.dart';
import '../data_sources/settlements_api.dart';
import '../data_sources/shop_services_api.dart';
import '../data_sources/shops_api.dart';
import '../models/shop_detail_response_model.dart';
import '../models/shop_service_response_model.dart';

/// Concrete shop repository using API exclusively.
/// No fallback to mock data - all errors propagate to UI.
class ShopsRepositoryImpl implements ShopsRepository {
  ShopsRepositoryImpl({
    ShopsApi? api,
    ShopsLocalDs? local,
    ShopServicesApi? servicesApi,
    SettlementsApi? settlementsApi,
  })  : _api = api ?? ShopsApi(),
        _local = local ?? const ShopsLocalDs(),
        _servicesApi = servicesApi ?? ShopServicesApi(),
        _settlementsApi = settlementsApi ?? SettlementsApi();

  final ShopsApi _api;
  final ShopsLocalDs _local;
  final ShopServicesApi _servicesApi;
  final SettlementsApi _settlementsApi;

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
                    vehicleType: v.type,
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
                    vehicleType: v.type,
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
  Future<List<Holiday>> fetchHolidays() => _local.fetchHolidays();

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
