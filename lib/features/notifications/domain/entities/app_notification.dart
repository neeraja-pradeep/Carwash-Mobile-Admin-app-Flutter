import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icons.dart';
import '../../../../app/theme/colors.dart';

/// Notification kind enum — maps to icon + color tone.
enum NotificationKind {
  booking,
  attention,
  refund,
  review,
  payout,
  system,
  promo,
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
    case NotificationKind.attention:
      return const NotificationTone(
        icon: AppIcons.alert,
        bg: AppColors.amberBg,
        fg: AppColors.amberFg,
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
    case NotificationKind.system:
      return const NotificationTone(
        icon: AppIcons.cal,
        bg: AppColors.amberBg,
        fg: AppColors.amberFg,
      );
    case NotificationKind.promo:
      return const NotificationTone(
        icon: AppIcons.tag,
        bg: AppColors.blueBg,
        fg: AppColors.blueFg,
      );
  }
}

/// A single admin notification item.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    this.body,
    required this.time,
    required this.unread,
    this.refBooking,
    this.refDiBooking,
    this.createdAt,
  });

  final int id;
  final NotificationKind kind;
  final String title;
  final String? body;
  final String time;
  final bool unread;

  /// Deep-link targets (at most one will be set).
  final int? refBooking;
  final int? refDiBooking;

  /// Raw ISO timestamp from API.
  final DateTime? createdAt;

  AppNotification copyWith({bool? unread}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      time: time,
      unread: unread ?? this.unread,
      refBooking: refBooking,
      refDiBooking: refDiBooking,
      createdAt: createdAt,
    );
  }
}
