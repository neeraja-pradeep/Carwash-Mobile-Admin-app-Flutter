import '../entities/app_notification.dart';

/// Contract for fetching the notification list.
abstract class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications();
}
