import '../entities/app_notification.dart';

/// Paginated notifications response.
class NotificationsPage {
  final List<AppNotification> items;
  final int total;
  final bool hasNextPage;
  final int? nextPageNumber;

  NotificationsPage({
    required this.items,
    required this.total,
    required this.hasNextPage,
    this.nextPageNumber,
  });
}

/// Contract for fetching notifications.
abstract class NotificationsRepository {
  /// Fetch notifications with optional pagination and filters.
  Future<NotificationsPage> fetchNotifications({
    int page = 1,
    int pageSize = 10,
    bool? isRead,
    String? kind,
  });

  /// Get unread notification count.
  Future<int> getUnreadCount();

  /// Mark a notification as read.
  Future<void> markAsRead(int notificationId);

  /// Mark all notifications as read.
  Future<int> markAllAsRead();
}
