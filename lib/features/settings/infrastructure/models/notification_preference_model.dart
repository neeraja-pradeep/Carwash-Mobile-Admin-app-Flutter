import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import 'json_helpers.dart';

/// Per-user `NotificationPreference` from
/// GET /api/accounts/v1/notification-preferences/.
class NotificationPreferenceModel {
  final bool newBooking;
  final bool refundRequests;
  final bool lowRatings;

  NotificationPreferenceModel({
    required this.newBooking,
    required this.refundRequests,
    required this.lowRatings,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationPreferenceModel(
        newBooking: asBool(json['new_booking'], true),
        refundRequests: asBool(json['refund_requests'], true),
        lowRatings: asBool(json['low_ratings'], true),
      );
    } catch (e) {
      debugPrint('Error parsing NotificationPreferenceModel: $e');
      rethrow;
    }
  }

  NotificationToggles toEntity() {
    return NotificationToggles(
      newBooking: newBooking,
      refundRequest: refundRequests,
      lowRating: lowRatings,
    );
  }
}

/// Builds the PATCH /notification-preferences/ payload (partial).
Map<String, dynamic> buildNotificationPayload({
  bool? newBooking,
  bool? refundRequests,
  bool? lowRatings,
}) {
  return {
    if (newBooking != null) 'new_booking': newBooking,
    if (refundRequests != null) 'refund_requests': refundRequests,
    if (lowRatings != null) 'low_ratings': lowRatings,
  };
}
