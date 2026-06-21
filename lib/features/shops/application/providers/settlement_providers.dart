import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/shops_repository.dart';
import 'shops_providers.dart';

/// Pending settlements for a shop
final pendingSettlementsProvider =
    FutureProvider.autoDispose.family<SettlementPending, String>((ref, shopId) async {
  final repository = ref.watch(shopsRepositoryProvider);
  return repository.fetchPendingSettlements(shopId);
});

/// Payout history for a shop
final payoutHistoryProvider =
    FutureProvider.autoDispose.family<SettlementHistory, String>((ref, shopId) async {
  final repository = ref.watch(shopsRepositoryProvider);
  return repository.fetchPayoutHistory(shopId);
});

/// Settlements overview (all shops for payout picker)
final settlementsOverviewProvider = FutureProvider.autoDispose<SettlementsOverview>((ref) async {
  final repository = ref.watch(shopsRepositoryProvider);
  return repository.fetchSettlementsOverview();
});
