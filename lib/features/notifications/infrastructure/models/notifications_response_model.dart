import '../../domain/entities/app_notification.dart';

/// Paginated notifications response from API.
class NotificationsListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<NotificationResponseModel> results;

  NotificationsListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NotificationsListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: ((json['results'] as List<dynamic>?) ?? [])
          .map((item) => NotificationResponseModel.fromJson(
            item as Map<String, dynamic>,
          ))
          .toList(),
    );
  }

  /// Get next page number from the `next` URL.
  int? getNextPage() {
    if (next == null) return null;
    try {
      final uri = Uri.parse(next!);
      return int.tryParse(uri.queryParameters['page'] ?? '');
    } catch (e) {
      return null;
    }
  }

  /// Check if there's a next page.
  bool get hasNextPage => next != null;
}

/// Single notification from API response.
class NotificationResponseModel {
  final int id;
  final String kind;
  final String title;
  final String? body;
  final int? refBooking;
  final int? refDiBooking;
  final bool isRead;
  final DateTime createdAt;

  NotificationResponseModel({
    required this.id,
    required this.kind,
    required this.title,
    this.body,
    this.refBooking,
    this.refDiBooking,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    return NotificationResponseModel(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      refBooking: json['ref_booking'] as int?,
      refDiBooking: json['ref_di_booking'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to domain entity.
  AppNotification toDomain() {
    return AppNotification(
      id: id,
      kind: _parseKind(kind),
      title: title,
      body: body,
      time: _getRelativeTime(createdAt),
      unread: !isRead,
      refBooking: refBooking,
      refDiBooking: refDiBooking,
      createdAt: createdAt,
    );
  }

  /// Parse kind string to enum.
  static NotificationKind _parseKind(String kind) {
    switch (kind) {
      case 'booking':
        return NotificationKind.booking;
      case 'attention':
        return NotificationKind.attention;
      case 'refund':
        return NotificationKind.refund;
      case 'review':
        return NotificationKind.review;
      case 'payout':
        return NotificationKind.payout;
      case 'system':
        return NotificationKind.system;
      case 'promo':
        return NotificationKind.promo;
      default:
        return NotificationKind.system;
    }
  }

  /// Get relative time string ("3 min ago", "Yesterday", etc.).
  static String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'Over a week ago';
    }
  }
}
