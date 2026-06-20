import '../../domain/repositories/notifications_repository.dart';
import '../data_sources/notifications_api.dart';

/// Concrete implementation using API.
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    NotificationsApi? api,
  }) : _api = api ?? NotificationsApi();

  final NotificationsApi _api;

  @override
  Future<NotificationsPage> fetchNotifications({
    int page = 1,
    int pageSize = 10,
    bool? isRead,
    String? kind,
  }) async {
    final response = await _api.getNotifications(
      page: page,
      pageSize: pageSize,
      isRead: isRead,
      kind: kind,
    );

    return NotificationsPage(
      items: response.results.map((r) => r.toDomain()).toList(),
      total: response.count,
      hasNextPage: response.hasNextPage,
      nextPageNumber: response.getNextPage(),
    );
  }

  @override
  Future<int> getUnreadCount() => _api.getUnreadCount();

  @override
  Future<void> markAsRead(int notificationId) =>
      _api.markAsRead(notificationId);

  @override
  Future<int> markAllAsRead() => _api.markAllAsRead();
}
