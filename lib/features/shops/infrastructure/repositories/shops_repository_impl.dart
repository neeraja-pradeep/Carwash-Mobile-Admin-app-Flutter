import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../data_sources/local/shops_local_ds.dart';
import '../data_sources/shops_api.dart';

/// Concrete shop repository using API exclusively.
/// No fallback to mock data - all errors propagate to UI.
class ShopsRepositoryImpl implements ShopsRepository {
  ShopsRepositoryImpl({
    ShopsApi? api,
    ShopsLocalDs? local,
  })  : _api = api ?? ShopsApi(),
        _local = local ?? const ShopsLocalDs();

  final ShopsApi _api;
  final ShopsLocalDs _local;

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
  Future<List<Holiday>> fetchHolidays() => _local.fetchHolidays();
}
