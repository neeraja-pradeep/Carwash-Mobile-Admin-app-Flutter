import '../entities/holiday.dart';
import '../entities/shop.dart';

/// Paginated shops response.
class ShopsPage {
  final List<Shop> items;
  final int total;
  final bool hasNextPage;
  final int? nextPageNumber;

  ShopsPage({
    required this.items,
    required this.total,
    required this.hasNextPage,
    this.nextPageNumber,
  });
}

/// Abstract contract for shop data access.
///
/// The infrastructure layer provides the implementation; the application layer
/// depends only on this interface — never on the concrete impl or the DS.
abstract class ShopsRepository {
  /// Returns paginated shops with optional search, filters, and sort.
  Future<ShopsPage> fetchShops({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? vehicleType,
    double? minRating,
    String? sort,
  });

  /// Returns shop detail by ID.
  Future<Shop> fetchShopDetail(String shopId);

  /// Returns all holidays (may span multiple shops).
  Future<List<Holiday>> fetchHolidays();
}
