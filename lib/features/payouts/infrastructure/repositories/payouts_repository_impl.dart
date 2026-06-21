import '../../domain/repositories/payouts_repository.dart';
import '../data_sources/payouts_api.dart';

/// Concrete payout repository using API exclusively (no mock data)
class PayoutsRepositoryImpl implements PayoutsRepository {
  PayoutsRepositoryImpl({
    PayoutsApi? api,
  }) : _api = api ?? PayoutsApi();

  final PayoutsApi _api;

  @override
  Future<PayoutsPage> fetchPayoutLog({
    String? search,
    String? status,
    String? shop,
    String? sort,
    int? days,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _api.getPayoutLog(
      search: search,
      status: status,
      shop: shop,
      sort: sort,
      days: days,
      page: page,
      pageSize: pageSize,
    );

    // Calculate next page number
    int? nextPageNumber;
    if (response.hasNextPage) {
      if (response.next != null) {
        final uri = Uri.parse(response.next!);
        final pageParam = uri.queryParameters['page'];
        if (pageParam != null) {
          nextPageNumber = int.tryParse(pageParam);
        }
      }
      nextPageNumber ??= page + 1;
    }

    return PayoutsPage(
      items: response.results
          .map((r) => PayoutLogItem(
                id: r.id,
                reference: r.reference,
                shop: r.shop,
                shopName: r.shopName,
                grossAmount: double.tryParse(r.grossAmount) ?? 0.0,
                commissionAmount: double.tryParse(r.commissionAmount) ?? 0.0,
                refundsTotal: double.tryParse(r.refundsTotal) ?? 0.0,
                otherAdjustments: double.tryParse(r.otherAdjustments) ?? 0.0,
                netOverride: r.netOverride != null
                    ? double.tryParse(r.netOverride!)
                    : null,
                totalAmount: double.tryParse(r.totalAmount) ?? 0.0,
                bookingCount: r.bookingCount,
                status: r.status,
                utr: r.utr,
                notes: r.notes,
                periodStart: r.periodStart,
                periodEnd: r.periodEnd,
                createdBy: r.createdBy,
                createdByName: r.createdByName,
                createdAt: DateTime.parse(r.createdAt),
                items: r.items
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
      total: response.count,
      hasNextPage: response.hasNextPage,
      nextPageNumber: nextPageNumber,
    );
  }
}
