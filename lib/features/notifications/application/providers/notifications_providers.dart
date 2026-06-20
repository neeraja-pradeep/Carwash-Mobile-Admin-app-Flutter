import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../infrastructure/repositories/notifications_repository_impl.dart';

/// The notifications repository (domain contract → infrastructure impl).
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(),
);

/// Filter state: 'all' | 'unread'.
final notificationsFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'all',
);

/// Current page number.
final notificationsPageProvider = StateProvider.autoDispose<int>(
  (ref) => 1,
);

/// Notifications for current page.
final notificationsProvider = FutureProvider.autoDispose<NotificationsPage>(
  (ref) {
    final filter = ref.watch(notificationsFilterProvider);
    final page = ref.watch(notificationsPageProvider);
    final repository = ref.watch(notificationsRepositoryProvider);

    final isRead = filter == 'unread' ? false : null;

    return repository.fetchNotifications(
      page: page,
      pageSize: 10,
      isRead: isRead,
    );
  },
);

/// Unread count from API.
final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return repository.getUnreadCount();
  },
);

/// Flattened notifications list (merges all pages for UI).
final allNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<AppNotification>>>((ref) {
  final currentPage = ref.watch(notificationsProvider);
  return currentPage.whenData((page) => page.items);
});
