import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../data_sources/local/shops_local_ds.dart';
import '../data_sources/shop_services_api.dart';
import '../data_sources/shops_api.dart';
import '../models/shop_service_response_model.dart';

/// Concrete shop repository using API exclusively.
/// No fallback to mock data - all errors propagate to UI.
class ShopsRepositoryImpl implements ShopsRepository {
  ShopsRepositoryImpl({
    ShopsApi? api,
    ShopsLocalDs? local,
    ShopServicesApi? servicesApi,
  })  : _api = api ?? ShopsApi(),
        _local = local ?? const ShopsLocalDs(),
        _servicesApi = servicesApi ?? ShopServicesApi();

  final ShopsApi _api;
  final ShopsLocalDs _local;
  final ShopServicesApi _servicesApi;

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
    } catch (e) {
      // Propagate the error - don't fallback to mock data
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
}
