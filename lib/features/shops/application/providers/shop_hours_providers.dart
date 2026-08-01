import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import 'shops_providers.dart';

/// The shop's editable weekly schedule (Manage Hours & Slots screen).
/// Distinct from `shopDetailProvider`'s read-only `operating_hours` summary.
final shopWeeklyScheduleProvider =
    FutureProvider.autoDispose.family<List<WeeklyDay>, String>((ref, shopId) {
  return ref.watch(shopsRepositoryProvider).fetchWeeklySchedule(shopId);
});

/// Saves the Hours & Slots screen and refreshes everything that read the old
/// values.
final saveShopHoursProvider =
    Provider<ShopHoursEditor>((ref) => ShopHoursEditor(ref));

class ShopHoursEditor {
  const ShopHoursEditor(this._ref);

  final Ref _ref;

  Future<void> call(
    String shopId, {
    required List<WeeklyDay> days,
    bool? useSlotLevelCapacity,
  }) async {
    final repository = _ref.read(shopsRepositoryProvider);
    await repository.saveWeeklySchedule(shopId, days);
    if (useSlotLevelCapacity != null) {
      await repository.updateShop(
        shopId,
        useSlotLevelCapacity: useSlotLevelCapacity,
      );
    }

    _ref.invalidate(shopWeeklyScheduleProvider(shopId));
    _ref.invalidate(shopDetailProvider(shopId));
    _ref.invalidate(shopByIdProvider(shopId));
  }
}

/// Creates/removes holidays and refreshes every affected shop's holiday list.
final holidayEditorProvider =
    Provider<HolidayEditor>((ref) => HolidayEditor(ref));

class HolidayEditor {
  const HolidayEditor(this._ref);

  final Ref _ref;

  Future<Holiday> create({
    required String date,
    required String label,
    required List<String> shopIds,
  }) async {
    final holiday = await _ref.read(shopsRepositoryProvider).createHoliday(
          date: date,
          label: label,
          shopIds: shopIds,
        );
    for (final shopId in shopIds) {
      _ref.invalidate(shopHolidaysProvider(shopId));
    }
    return holiday;
  }

  Future<void> delete(String holidayId, {required List<String> shopIds}) async {
    await _ref.read(shopsRepositoryProvider).deleteHoliday(holidayId);
    for (final shopId in shopIds) {
      _ref.invalidate(shopHolidaysProvider(shopId));
    }
  }
}
