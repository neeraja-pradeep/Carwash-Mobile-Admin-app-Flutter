import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../data_sources/local/notifications_local_ds.dart';

/// Concrete implementation that delegates to [NotificationsLocalDs].
class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._ds);

  final NotificationsLocalDs _ds;

  @override
  Future<List<AppNotification>> fetchNotifications() => _ds.fetchNotifications();
}
