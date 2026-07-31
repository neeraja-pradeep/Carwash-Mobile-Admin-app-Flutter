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

  /// Creates a new shop with the provided details.
  ///
  /// [latitude] / [longitude] come from the address field's map picker and are
  /// null when the admin saved without picking a point.
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
  });

  /// Applies the edited details to an existing shop.
  ///
  /// Partial: omitted arguments are not sent, so a column the form has no input
  /// for keeps its stored value rather than being blanked.
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
  });

  /// Returns services for a shop.
  Future<List<ShopService>> fetchShopServices(String shopId);

  /// Create a new service.
  Future<ShopService> createService(
    String shopId,
    String name,
    List<String> inclusions,
    bool uniformPricing,
    bool active,
    int? price,
    int? durationInSlots,
    List<({String type, int price, int minutes, bool active})>? variants,
  );

  /// Update a service.
  Future<ShopService> updateService(
    int serviceId,
    String name,
    List<String> inclusions,
    bool uniformPricing,
    bool active,
    int? price,
    int? durationInSlots,
    List<({String type, int price, int minutes, bool active})>? variants,
  );

  /// Toggle service active status.
  Future<ShopService> toggleService(int serviceId, bool active);

  /// Copy services from source shop to target shop.
  Future<({int copied, int skipped})> copyServices(
    int sourceShopId,
    int targetShopId,
  );

  /// Apply percentage price change to all services in a shop.
  Future<({int servicesUpdated, int variantsUpdated})> applyPriceChange(
    String shopId,
    double percent,
  );

  /// Returns all holidays (may span multiple shops).
  Future<List<Holiday>> fetchHolidays();

  /// Get pending settlements for a shop.
  Future<SettlementPending> fetchPendingSettlements(String shopId);

  /// Create payout for a shop.
  Future<SettlementPayout> createPayout(
    String shopId, {
    String? utr,
    String? notes,
  });

  /// Get payout history for a shop.
  Future<SettlementHistory> fetchPayoutHistory(String shopId);

  /// Get settlements overview (all shops for payout picker).
  Future<SettlementsOverview> fetchSettlementsOverview();
}

/// Settlement domain entities
class SettlementPending {
  final int shopId;
  final int count;
  final double netPayable;
  final double pendingTotal;
  final DateTime? lastSettled;
  final double lifetimePaid;
  final List<SettlementItemData> items;

  SettlementPending({
    required this.shopId,
    required this.count,
    required this.netPayable,
    required this.pendingTotal,
    this.lastSettled,
    required this.lifetimePaid,
    required this.items,
  });
}

class SettlementItemData {
  final int bookingId;
  final String reference;
  final String appointmentDate;
  final double gross;
  final double commission;
  final double net;

  SettlementItemData({
    required this.bookingId,
    required this.reference,
    required this.appointmentDate,
    required this.gross,
    required this.commission,
    required this.net,
  });
}

class SettlementPayout {
  final int id;
  final int shop;
  final double grossAmount;
  final double commissionAmount;
  final double totalAmount;
  final int bookingCount;
  final String status;
  final String? utr;
  final String? notes;
  final String periodStart;
  final String periodEnd;
  final int createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<PayoutItemData> items;

  SettlementPayout({
    required this.id,
    required this.shop,
    required this.grossAmount,
    required this.commissionAmount,
    required this.totalAmount,
    required this.bookingCount,
    required this.status,
    this.utr,
    this.notes,
    required this.periodStart,
    required this.periodEnd,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.items,
  });
}

class PayoutItemData {
  final int id;
  final int booking;
  final String reference;
  final String appointmentDate;
  final double gross;
  final double commission;
  final double net;

  PayoutItemData({
    required this.id,
    required this.booking,
    required this.reference,
    required this.appointmentDate,
    required this.gross,
    required this.commission,
    required this.net,
  });
}

class SettlementHistory {
  final int count;
  final List<SettlementPayout> payouts;

  SettlementHistory({required this.count, required this.payouts});
}

class SettlementsOverview {
  final int count;
  final List<SettlementOverviewShop> shops;

  SettlementsOverview({required this.count, required this.shops});
}

class SettlementOverviewShop {
  final int shopId;
  final String name;
  final double pendingTotal;
  final int bookingCount;
  final DateRange? period;
  final LastPaid? lastPaid;

  SettlementOverviewShop({
    required this.shopId,
    required this.name,
    required this.pendingTotal,
    required this.bookingCount,
    this.period,
    this.lastPaid,
  });
}

class DateRange {
  final String start;
  final String end;

  DateRange({required this.start, required this.end});
}

class LastPaid {
  final DateTime date;
  final double amount;

  LastPaid({required this.date, required this.amount});
}
