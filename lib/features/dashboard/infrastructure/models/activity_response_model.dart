import 'package:intl/intl.dart';

import '../../domain/entities/activity_item.dart';

/// API response from GET /api/booking/v1/admin/recent-activity/
class ActivityResponseModel {
  final int id;
  final String verb;
  final String title;
  final String subtitle;
  final int? booking;
  final String? bookingReference;
  final int? diBooking;
  final String? diBookingReference;
  final String reference;
  final DateTime createdAt;

  ActivityResponseModel({
    required this.id,
    required this.verb,
    required this.title,
    required this.subtitle,
    this.booking,
    this.bookingReference,
    this.diBooking,
    this.diBookingReference,
    required this.reference,
    required this.createdAt,
  });

  factory ActivityResponseModel.fromJson(Map<String, dynamic> json) {
    return ActivityResponseModel(
      id: json['id'] as int? ?? 0,
      verb: json['verb'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      booking: json['booking'] as int?,
      bookingReference: json['booking_reference'] as String?,
      diBooking: json['di_booking'] as int?,
      diBookingReference: json['di_booking_reference'] as String?,
      reference: json['reference'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  ActivityItem toDomain() {
    return ActivityItem(
      iconKey: _verbToIconKey(verb),
      text: '$title · $subtitle',
      time: _getRelativeTime(createdAt),
      bookingId: booking?.toString() ?? diBooking?.toString() ?? reference,
      verb: verb,
      title: title,
      subtitle: subtitle,
      reference: reference,
      isBooking: booking != null,
    );
  }

  static String _verbToIconKey(String verb) {
    switch (verb) {
      case 'booking_created':
        return 'inbox';
      case 'wash_done':
        return 'droplet';
      case 'returning':
        return 'car';
      case 'refund_issued':
        return 'receipt';
      case 'review_created':
        return 'star';
      case 'driver_assigned':
        return 'car';
      case 'booking_cancelled':
        return 'inbox';
      case 'damage_reported':
        return 'alert';
      case 'payout_created':
        return 'wallet';
      case 'di_request_created':
        return 'users';
      case 'di_assigned':
        return 'users';
      case 'di_completed':
        return 'nav';
      default:
        return 'inbox';
    }
  }

  static String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
