import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/shop.dart';
import 'shops_providers.dart';

/// Services for a specific shop (autoDispose so detail screens reset when popped).
final shopServicesProvider =
    FutureProvider.autoDispose.family<List<ShopService>, String>(
  (ref, shopId) async {
    final repository = ref.watch(shopsRepositoryProvider);
    return repository.fetchShopServices(shopId);
  },
);
