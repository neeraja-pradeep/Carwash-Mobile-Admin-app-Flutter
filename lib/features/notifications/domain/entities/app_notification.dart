import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icons.dart';
import '../../../../app/theme/colors.dart';

/// Notification kind enum — maps to icon + color tone.
enum NotificationKind {
  booking,
  overdue,
  wash,
  refund,
  review,
  payout,
  holiday,
}

/// Icon + colour mapping for a notification kind.
class NotificationTone {
  const NotificationTone({
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
}

/// Returns the [NotificationTone] for a given [NotificationKind].
NotificationTone toneFor(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.booking:
      return const NotificationTone(
        icon: AppIcons.inbox,
        bg: AppColors.blueBg,
        fg: AppColors.blueFg,
      );
    case NotificationKind.overdue:
      return const NotificationTone(
        icon: AppIcons.alert,
        bg: AppColors.amberBg,
        fg: AppColors.amberFg,
      );
    case NotificationKind.wash:
      return const NotificationTone(
        icon: AppIcons.droplet,
        bg: AppColors.blueBg,
        fg: AppColors.blueFg,
      );
    case NotificationKind.refund:
      return const NotificationTone(
        icon: AppIcons.receipt,
        bg: AppColors.amberBg,
        fg: AppColors.amberFg,
      );
    case NotificationKind.review:
      return const NotificationTone(
        icon: AppIcons.star,
        bg: AppColors.greenBg,
        fg: AppColors.greenFg,
      );
    case NotificationKind.payout:
      return const NotificationTone(
        icon: AppIcons.wallet,
        bg: AppColors.greenBg,
        fg: AppColors.greenFg,
      );
    case NotificationKind.holiday:
      return const NotificationTone(
        icon: AppIcons.cal,
        bg: AppColors.amberBg,
        fg: AppColors.amberFg,
      );
  }
}

/// A single admin notification item (from `data.jsx` NOTIFICATIONS).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
    this.dateGroup = 'Today',
    this.bookingId,
    this.refundId,
    this.reviewId,
    this.payoutId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String time;
  final bool unread;

  /// Human-readable date-bucket label, e.g. 'Today' or 'Yesterday'.
  /// Used to render section headers in the notifications list.
  final String dateGroup;

  /// Deep-link targets (at most one will be set).
  final String? bookingId;
  final String? refundId;
  final String? reviewId;
  final String? payoutId;

  AppNotification copyWith({bool? unread}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      time: time,
      unread: unread ?? this.unread,
      dateGroup: dateGroup,
      bookingId: bookingId,
      refundId: refundId,
      reviewId: reviewId,
      payoutId: payoutId,
    );
  }
}
