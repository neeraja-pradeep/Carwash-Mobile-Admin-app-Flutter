import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../infrastructure/data_sources/local/notifications_local_ds.dart';
import '../../infrastructure/repositories/notifications_repository_impl.dart';

/// Local data source (swapped for remote+cache in API phase).
final notificationsLocalDsProvider = Provider<NotificationsLocalDs>(
  (ref) => const NotificationsLocalDs(),
);

/// The notifications repository (domain contract → infrastructure impl).
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(ref.watch(notificationsLocalDsProvider)),
);

/// All notifications (read). Kept alive so navigating back is instant.
final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationsRepositoryProvider).fetchNotifications(),
);

/// Mutable, per-session read-state (marks individual items as read).
/// autoDispose resets when the screen is popped.
final notificationsReadStateProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);

/// Filter state: 'all' | 'unread'.
final notificationsFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'all',
);

/// Derived: merge server unread with local read-state and apply filter.
final filteredNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<AppNotification>>>((ref) {
  final raw = ref.watch(notificationsProvider);
  final readIds = ref.watch(notificationsReadStateProvider);
  final filter = ref.watch(notificationsFilterProvider);
  return raw.whenData((list) {
    // Apply local read marks (marks as read without a round-trip in the static phase).
    final effective = list
        .map((n) => readIds.contains(n.id) ? n.copyWith(unread: false) : n)
        .toList();
    if (filter == 'unread') {
      return effective.where((n) => n.unread).toList();
    }
    return effective;
  });
});

/// Derived unread count after applying local read marks.
final unreadCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final raw = ref.watch(notificationsProvider);
  final readIds = ref.watch(notificationsReadStateProvider);
  return raw.whenData(
    (list) => list.where((n) => n.unread && !readIds.contains(n.id)).length,
  );
});
