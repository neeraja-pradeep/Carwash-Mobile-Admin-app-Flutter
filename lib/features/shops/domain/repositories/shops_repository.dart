import '../entities/holiday.dart';
import '../entities/shop.dart';

/// Abstract contract for shop data access.
///
/// The infrastructure layer provides the implementation; the application layer
/// depends only on this interface — never on the concrete impl or the DS.
abstract class ShopsRepository {
  /// Returns all shops in the catalogue.
  Future<List<Shop>> fetchShops();

  /// Returns all holidays (may span multiple shops).
  Future<List<Holiday>> fetchHolidays();
}
